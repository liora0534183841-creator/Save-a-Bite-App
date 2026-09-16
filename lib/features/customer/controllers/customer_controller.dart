import 'package:flutter/material.dart';

/// Controller responsible for managing the local UI state of customer-facing screens.
/// Handles interactions such as view toggling, active city filtering, search queries, and order form state.
class CustomerController extends ChangeNotifier {
  // --- View State Management (Map vs. List) ---

  bool _isMapView = false;

  /// Returns [true] if the Home Screen is currently displaying the Map View layout.
  bool get isMapView => _isMapView;

  /// Toggles the main display layout between Map View and List View.
  /// Triggers a UI rebuild to reflect the layout change immediately.
  void toggleView() {
    _isMapView = !_isMapView;
    notifyListeners();
  }

  // --- Location & Filtering State ---

  String _selectedCity = '';

  /// The currently selected city used to filter available packages.
  String get selectedCity => _selectedCity;

  /// Updates the active city filter and triggers a UI rebuild for dependent widgets.
  void changeCity(String newCity) {
    _selectedCity = newCity;
    notifyListeners();
  }

  // --- Search State Management ---

  String _searchQuery = '';

  /// The current keyword typed in the search input field.
  String get searchQuery => _searchQuery;

  /// Updates the search query string and triggers a UI rebuild for dynamic filtering.
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // --- Order Popup State Management ---

  bool _isTermsChecked = false;

  /// Indicates whether the user has agreed to the Terms of Service within the order confirmation popup.
  bool get isTermsChecked => _isTermsChecked;

  /// Updates the terms agreement checkbox state.
  /// Used to dynamically enable or disable the final order confirmation button.
  void setTermsChecked(bool value) {
    _isTermsChecked = value;
    notifyListeners();
  }

  /// Resets the order form state back to default values.
  /// Called upon closing the order dialog to prevent state leakage to subsequent orders.
  void resetOrderForm() {
    _isTermsChecked = false;
    notifyListeners();
  }
}
