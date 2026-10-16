String formatDeliveryMoney(dynamic value) {
  final text = value?.toString().replaceAll('.', ',') ?? '0,00';
  return 'R\$ $text';
}

List<Map<String, dynamic>> filterDeliveryZones({
  required List<Map<String, dynamic>> zones,
  required String query,
  required bool? activeFilter,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return zones.where((zone) {
    final matchesStatus =
        activeFilter == null || zone['is_active'] == activeFilter;
    final text = [
      zone['name'],
      zone['city'],
      zone['neighborhood'],
    ].whereType<Object>().join(' ').toLowerCase();
    return matchesStatus &&
        (normalizedQuery.isEmpty || text.contains(normalizedQuery));
  }).toList();
}
