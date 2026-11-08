// Gene - Nov, 08, 2026: Automated verification suite for Vercel Web Beta deployment config, CSP/HSTS headers, Edge Function auth guards, and Wasm/Web portability
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookit/core/constants/supabase_config.dart';

void main() {
  group('Vercel Web Beta & Full-Stack Security Readiness Suite', () {
    test('vercel.json is valid JSON with SPA rewrites and strict security headers', () {
      final file = File('vercel.json');
      expect(file.existsSync(), isTrue, reason: 'vercel.json must exist at repository root');

      final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(jsonMap['outputDirectory'], equals('build/web'));
      expect(jsonMap['cleanUrls'], isTrue);

      final rewrites = jsonMap['rewrites'] as List<dynamic>;
      expect(rewrites, isNotEmpty);
      expect(rewrites.first['source'], equals('/(.*)'));
      expect(rewrites.first['destination'], equals('/index.html'));

      final headersList = jsonMap['headers'] as List<dynamic>;
      final globalHeadersEntry = headersList.firstWhere((h) => h['source'] == '/(.*)');
      final headerMap = <String, String>{
        for (final h in (globalHeadersEntry['headers'] as List<dynamic>))
          h['key'] as String: h['value'] as String,
      };

      expect(headerMap.containsKey('Content-Security-Policy'), isTrue);
      expect(headerMap['Content-Security-Policy'], contains("frame-ancestors 'none'"));
      expect(headerMap['Content-Security-Policy'], contains('https://www.gstatic.com'));
      expect(headerMap['Strict-Transport-Security'], contains('max-age=63072000'));
      expect(headerMap['X-Content-Type-Options'], equals('nosniff'));
      expect(headerMap['X-Frame-Options'], equals('DENY'));
      expect(headerMap['Referrer-Policy'], equals('strict-origin-when-cross-origin'));
      expect(headerMap['Permissions-Policy'], contains('camera=(self)'));
      expect(headerMap['Permissions-Policy'], contains('geolocation=(self)'));
    });

    test('web/index.html and web/manifest.json contain BookIt branding and splash screen', () {
      final indexHtml = File('web/index.html').readAsStringSync();
      expect(indexHtml, contains('BookIt — Universal Booking & Clinic Management Platform'));
      expect(indexHtml, contains('og:title'));
      expect(indexHtml, contains('id="bookit-splash"'));
      expect(indexHtml, contains('flutter-first-frame'));

      final manifestJson = jsonDecode(File('web/manifest.json').readAsStringSync()) as Map<String, dynamic>;
      expect(manifestJson['short_name'], equals('BookIt'));
      expect(manifestJson['theme_color'], equals('#009688'));
      expect(manifestJson['background_color'], equals('#12181F'));
    });

    test('No unguarded dart:io imports exist in lib/ outside test_environment_io.dart', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        if (file.path.endsWith('test_environment_io.dart')) continue;
        final lines = file.readAsLinesSync();
        bool inBlockComment = false;
        for (final rawLine in lines) {
          final line = rawLine.trim();
          if (line.startsWith('/*')) inBlockComment = true;
          if (!inBlockComment && !line.startsWith('//')) {
            expect(
              line.contains("import 'dart:io'") || line.contains('import "dart:io"'),
              isFalse,
              reason: 'Unguarded dart:io import found in ${file.path}: $line',
            );
          }
          if (line.endsWith('*/') || line.contains('*/')) inBlockComment = false;
        }
      }
    });

    test('Supabase Edge Functions and SQL migrations enforce auth and RBAC guards', () {
      final dispatchReminders = File('supabase/functions/dispatch-reminders/index.ts').readAsStringSync();
      expect(dispatchReminders, contains('CRON_SECRET'));
      expect(dispatchReminders, contains('status: 401'));

      final connectOnboarding = File('supabase/functions/connect-onboarding/index.ts').readAsStringSync();
      expect(connectOnboarding, contains('isAllowedRedirectUrl'));
      expect(connectOnboarding, contains('Unauthorized: Authentication required for Stripe Connect onboarding'));

      final createCheckout = File('supabase/functions/create-checkout-session/index.ts').readAsStringSync();
      expect(createCheckout, contains('isAllowedRedirectUrl'));
      expect(createCheckout, contains('Unauthorized: Authentication required to create a checkout session'));

      final hardeningMigration = File('supabase/migrations/20261108000001_web_beta_security_hardening.sql').readAsStringSync();
      expect(hardeningMigration, contains('REVOKE EXECUTE ON FUNCTION public.get_business_crm_profiles(UUID, INT, INT) FROM anon;'));
      expect(hardeningMigration, contains('chk_bookings_non_negative_amounts'));
    });

    test('SupabaseConfig validates HTTPS transport security and override flags', () {
      expect(SupabaseConfig.isSecureUrl, isTrue);
      SupabaseConfig.overrideConfigured = false;
      expect(SupabaseConfig.isConfigured, isFalse);
      SupabaseConfig.overrideConfigured = null;
    });
  });
}
