class CategoryTermHelper {
  static String getPluralTerm(String? category) {
    final cat = category?.toLowerCase() ?? '';
    switch (cat) {
      case 'education': return 'Courses';
      case 'health':
      case 'services':
      case 'publicservices':
      case 'public services': return 'Services';
      case 'religious': return 'Programs';
      case 'entertainment': return 'Events';
      default: return 'Products';
    }
  }

  static String getSingularTerm(String? category) {
    final cat = category?.toLowerCase() ?? '';
    switch (cat) {
      case 'education': return 'Course';
      case 'health':
      case 'services':
      case 'publicservices':
      case 'public services': return 'Service';
      case 'religious': return 'Program';
      case 'entertainment': return 'Event';
      default: return 'Product';
    }
  }

  static bool isOfferingCategory(String? category) {
    final cat = category?.toLowerCase().replaceAll(' ', '') ?? '';
    return ['education', 'publicservices', 'finance', 'religious', 'entertainment'].contains(cat);
  }
}
