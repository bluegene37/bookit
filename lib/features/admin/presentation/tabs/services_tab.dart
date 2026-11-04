// Gene - Nov, 04, 2026: Added Payments & Invoices tab navigation and service payment policy configuration
export '../services_manager_tab.dart';
import 'package:flutter/material.dart';
import '../../../../models/business.dart';
import '../services_manager_tab.dart';

class ServicesTab extends StatelessWidget {
  final Business business;

  const ServicesTab({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return ServicesManagerTab(business: business);
  }
}
