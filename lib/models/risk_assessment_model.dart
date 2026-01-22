import 'package:flutter/material.dart';

class RiskAssessmentModel {
  final int riskScore;
  final String riskLevel;
  final Map<String, dynamic> factors;
  final List<String> recommendations;
  final DateTime lastUpdated;

  RiskAssessmentModel({
    required this.riskScore,
    required this.riskLevel,
    required this.factors,
    required this.recommendations,
    required this.lastUpdated,
  });

  factory RiskAssessmentModel.fromJson(Map<String, dynamic> json) {
    return RiskAssessmentModel(
      riskScore: json['riskScore'],
      riskLevel: json['riskLevel'],
      factors: json['factors'],
      recommendations: List<String>.from(json['recommendations']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Color getRiskColor() {
    if (riskScore < 30) return Colors.green;
    if (riskScore < 60) return Colors.orange;
    return Colors.red;
  }

  String getRiskEmoji() {
    if (riskScore < 30) return '✅';
    if (riskScore < 60) return '⚠️';
    return '🚨';
  }
}