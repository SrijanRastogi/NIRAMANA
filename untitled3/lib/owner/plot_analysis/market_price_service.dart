import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Market Price Service
/// Tracks real estate prices per square foot by city/pincode in India (2026)
/// Provides market-based pricing for generated building concepts
class MarketPriceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get market price per square foot for a given city/pincode
  /// Returns price in INR per sq ft
  /// Falls back to city-level average if pincode not found
  static Future<double> getPricePerSqFt(String cityOrPincode) async {
    try {
      // First try to find by pincode
      if (cityOrPincode.length == 6 && int.tryParse(cityOrPincode) != null) {
        final pincodeDoc = await _firestore
            .collection('market_prices')
            .doc('pincode_$cityOrPincode')
            .get();

        if (pincodeDoc.exists) {
          final data = pincodeDoc.data() as Map<String, dynamic>;
          return (data['pricePerSqFt'] as num?)?.toDouble() ?? 5000.0;
        }
      }

      // Fall back to city-level pricing
      final cityDoc = await _firestore
          .collection('market_prices')
          .doc('city_${cityOrPincode.toLowerCase()}')
          .get();

      if (cityDoc.exists) {
        final data = cityDoc.data() as Map<String, dynamic>;
        return (data['pricePerSqFt'] as num?)?.toDouble() ?? 5000.0;
      }

      // Default fallback price for India (2026 estimate)
      return _getDefaultPriceByCity(cityOrPincode);
    } catch (e) {
      debugPrint('Error fetching market price: $e');
      return _getDefaultPriceByCity(cityOrPincode);
    }
  }

  /// Get default market prices by major Indian cities (2026 estimates)
  static double _getDefaultPriceByCity(String city) {
    final cityLower = city.toLowerCase();

    // Major metros and cities with estimated 2026 prices (INR per sq ft)
    final priceMap = {
      'mumbai': 15000.0,
      'bangalore': 12000.0,
      'delhi': 14000.0,
      'hyderabad': 10000.0,
      'pune': 9000.0,
      'chennai': 8500.0,
      'kolkata': 7000.0,
      'ahmedabad': 7500.0,
      'jaipur': 6500.0,
      'lucknow': 5500.0,
      'indore': 5000.0,
      'surat': 6000.0,
      'vadodara': 5500.0,
      'nagpur': 4500.0,
      'bhopal': 4500.0,
      'chandigarh': 7000.0,
      'kochi': 8000.0,
      'visakhapatnam': 6000.0,
      'coimbatore': 6500.0,
      'gurgaon': 13000.0,
      'noida': 11000.0,
      'thane': 12000.0,
      'navi mumbai': 11000.0,
    };

    // Check if city matches any key
    for (final entry in priceMap.entries) {
      if (cityLower.contains(entry.key) || entry.key.contains(cityLower)) {
        return entry.value;
      }
    }

    // Default for unknown cities
    return 5000.0;
  }

  /// Calculate total market price for a building
  /// Parameters:
  /// - buildingAreaSqFt: Total built-up area in square feet
  /// - pricePerSqFt: Market price per square foot
  /// Returns: Total estimated price in INR
  static double calculateTotalPrice(double buildingAreaSqFt, double pricePerSqFt) {
    return buildingAreaSqFt * pricePerSqFt;
  }

  /// Convert square meters to square feet
  static double sqMeterToSqFt(double sqMeter) {
    return sqMeter * 10.764; // 1 sq meter = 10.764 sq feet
  }

  /// Convert square feet to square meters
  static double sqFtToSqMeter(double sqFt) {
    return sqFt / 10.764;
  }

  /// Format price in Indian Rupees with proper notation
  /// Examples: ₹50 Lakhs, ₹1.5 Crores
  static String formatPrice(double priceInRupees) {
    if (priceInRupees >= 10000000) {
      // Crores
      final crores = priceInRupees / 10000000;
      return '₹${crores.toStringAsFixed(2)} Cr';
    } else if (priceInRupees >= 100000) {
      // Lakhs
      final lakhs = priceInRupees / 100000;
      return '₹${lakhs.toStringAsFixed(2)} L';
    } else {
      // Thousands
      final thousands = priceInRupees / 1000;
      return '₹${thousands.toStringAsFixed(2)} K';
    }
  }

  /// Get market price summary for a location
  static Future<Map<String, dynamic>> getMarketSummary(String cityOrPincode) async {
    try {
      final pricePerSqFt = await getPricePerSqFt(cityOrPincode);

      return {
        'location': cityOrPincode,
        'pricePerSqFt': pricePerSqFt,
        'formattedPrice': '₹${pricePerSqFt.toStringAsFixed(0)}/sq ft',
        'lastUpdated': DateTime.now(),
        'source': 'Market Data 2026',
      };
    } catch (e) {
      return {
        'location': cityOrPincode,
        'pricePerSqFt': 5000.0,
        'formattedPrice': '₹5000/sq ft',
        'lastUpdated': DateTime.now(),
        'source': 'Default Estimate',
        'error': e.toString(),
      };
    }
  }
}
