abstract final class AdminCustomerFilters {
  static List<Map<String, dynamic>> visible({
    required List<Map<String, dynamic>> customers,
    required String query,
    required bool? activeFilter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return customers.where((customer) {
      final matchesStatus =
          activeFilter == null || customer['is_active'] == activeFilter;
      final name = customer['name']?.toString().toLowerCase() ?? '';
      final email = customer['email']?.toString().toLowerCase() ?? '';
      return matchesStatus &&
          (normalizedQuery.isEmpty ||
              name.contains(normalizedQuery) ||
              email.contains(normalizedQuery));
    }).toList();
  }
}
