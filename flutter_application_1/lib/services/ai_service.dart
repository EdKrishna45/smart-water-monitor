import 'dart:math';

class AIService {
  /// Simulates an AI/ML Heuristic model that corrects Raw Turbidity based on environmental conditions.
  /// Standard light scatter (turbidity) sensors suffer interference from ambient light and thermal drifts.
  static double calculateTrueTurbidity(double rawTurbidity, String lightCondition, double temperature) {
    double correction = 0.0;

    // 1. Ambient Light Interference Correction
    if (lightCondition == 'High') {
      // Direct sunlight bleaches detectors, making water appear clearer than it is. We correct upwards.
      correction += 2.8;
    } else if (lightCondition == 'Low') {
      // Pitch black environment reduces background scattering signals. We correct slightly downwards.
      correction -= 0.9;
    }

    // 2. Temperature Thermal Drift Correction
    // Sensors are calibrated at 20°C. Standard deviation from 20°C induces diode drift.
    double tempDev = temperature - 20.0;
    correction += 0.03 * tempDev;

    double trueTurbidity = rawTurbidity + correction;
    return max(0.0, double.parse(trueTurbidity.toStringAsFixed(2)));
  }

  /// Computes the Water Quality Index (WQI) out of 100.
  /// Considers pH (ideal 7.0), Turbidity (ideal < 1.0 NTU), and Temperature (ideal 15-22°C).
  static double calculateWQI(double ph, double trueTurbidity, double temperature) {
    // 1. pH Rating (0-100)
    // Deviation from neutral pH 7.0 decreases quality. pH below 4 or above 10 is critically bad.
    double phRating = 100 - (ph - 7.0).abs() * 25;
    phRating = max(0.0, min(100.0, phRating));

    // 2. Turbidity Rating (0-100)
    // WHO standard requires < 5 NTU for safe water, ideally < 1 NTU. Above 25 NTU is extremely murky.
    double turbidityRating = 100 - (trueTurbidity * 4.5);
    turbidityRating = max(0.0, min(100.0, turbidityRating));

    // 3. Temperature Rating (0-100)
    // Warm temperatures foster bacterial growth. Ideal is 18°C. Above 38°C or below 4°C reduces index.
    double tempRating = 100 - (temperature - 18.0).abs() * 3.5;
    tempRating = max(0.0, min(100.0, tempRating));

    // Weighted index: Turbidity (45%), pH (35%), Temperature (20%)
    double wqi = (turbidityRating * 0.45) + (phRating * 0.35) + (tempRating * 0.20);
    return double.parse(wqi.toStringAsFixed(1));
  }

  /// Classifies safety state and returns ('Safe' | 'Warning' | 'Danger')
  static String determineSafetyStatus(double ph, double trueTurbidity, double wqi) {
    if (wqi >= 80.0 && ph >= 6.5 && ph <= 8.5 && trueTurbidity <= 5.0) {
      return 'Safe';
    } else if (wqi >= 50.0 && ph >= 6.0 && ph <= 9.0 && trueTurbidity <= 15.0) {
      return 'Warning';
    } else {
      return 'Danger';
    }
  }

  /// AI Advisory recommendations based on parameters
  static String generateAdvisoryAdvice(double ph, double trueTurbidity, double temperature, String status) {
    if (status == 'Safe') {
      return '✅ Water is clean and safe for drinking, cooking, and consumption. All parameters are within ideal environmental thresholds.';
    }

    List<String> insights = [];

    // Analyze specific anomalies
    if (ph < 6.5) {
      insights.add('Acidic pH ($ph): Can cause piping corrosion and metallic taste.');
    } else if (ph > 8.5) {
      insights.add('Alkaline pH ($ph): Slippery feel, scale deposition, and reduced chlorination power.');
    }

    if (trueTurbidity > 5.0 && trueTurbidity <= 15.0) {
      insights.add('Moderate Turbidity ($trueTurbidity NTU): Suspended particles present. Risk of micro-organisms.');
    } else if (trueTurbidity > 15.0) {
      insights.add('High Turbidity ($trueTurbidity NTU): Extremely cloudy. Pathogenic bacteria, viruses, or parasites could be present.');
    }

    if (temperature > 28.0) {
      insights.add('High Temperature ($temperature°C): Ideal incubation temperature for micro-organisms.');
    }

    if (status == 'Warning') {
      return '⚠️ MODERATE CAUTION:\n'
             '${insights.join('\n')}\n\n'
             '👉 RECOMMENDATION: Boil water for at least 1-3 minutes before drinking, or filter through carbon membranes.';
    } else {
      return '❌ DANGER: CRITICAL WATER CONTAMINATION!\n'
             '${insights.join('\n')}\n\n'
             '👉 RECOMMENDATION: DO NOT CONSUME. Requires professional chemical flocculation, reverse osmosis filtration, or UV disinfection before any household use.';
    }
  }
}
