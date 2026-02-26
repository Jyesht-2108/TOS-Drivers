// Student list screen with advanced filtering and sorting

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/route.dart' as models;
import '../../../models/student.dart';
import '../../../services/route_service.dart';
import '../../../providers/auth_provider.dart';

enum SortOption {
  nameAsc,
  nameDesc,
  gradeAsc,
  gradeDesc,
}

final studentRoutesProvider = FutureProvider<List<models.Route>>((ref) async {
  final authState = ref.watch(authProvider);
  final routeService = RouteService();
  
  if (authState.user == null) {
    return [];
  }
  
  return await routeService.getAssignedRoutes(authState.user!.id);
});

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  String _searchQuery = '';
  String? _selectedRouteId;
  SortOption _sortOption = SortOption.nameAsc;

  Future<void> _callParent(BuildContext context, Student student) async {
    if (student.parentPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parent phone number not available')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Parent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${student.name}'),
            const SizedBox(height: 8),
            Text('Parent: ${student.parentName ?? "Unknown"}'),
            const SizedBox(height: 8),
            Text('Phone: ${student.parentPhone}'),
            const SizedBox(height: 16),
            const Text('Do you want to call this parent?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.phone),
            label: const Text('Call'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final phoneNumber = student.parentPhone!.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$phoneNumber');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch phone dialer')),
          );
        }
      }
    }
  }

  void _showFilterOptions(BuildContext context, List<models.Route> routes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Sort',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Route Filter
            Text(
              'Filter by Route',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All Routes'),
                  selected: _selectedRouteId == null,
                  onSelected: (selected) {
                    setState(() => _selectedRouteId = null);
                    Navigator.pop(context);
                  },
                ),
                ...routes.map((route) => ChoiceChip(
                  label: Text(route.name),
                  selected: _selectedRouteId == route.id,
                  onSelected: (selected) {
                    setState(() => _selectedRouteId = route.id);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
            const SizedBox(height: 24),
            
            // Sort Options
            Text(
              'Sort by',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Name (A-Z)'),
              trailing: _sortOption == SortOption.nameAsc
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _sortOption = SortOption.nameAsc);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Name (Z-A)'),
              trailing: _sortOption == SortOption.nameDesc
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _sortOption = SortOption.nameDesc);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Grade (Low to High)'),
              trailing: _sortOption == SortOption.gradeAsc
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _sortOption = SortOption.gradeAsc);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Grade (High to Low)'),
              trailing: _sortOption == SortOption.gradeDesc
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _sortOption = SortOption.gradeDesc);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetails(BuildContext context, Student student, String routeName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Student Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        student.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (student.grade != null)
                            Text(
                              student.grade!,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          Text(
                            routeName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Parent Information
                Text(
                  'Parent Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  icon: Icons.person,
                  label: 'Parent Name',
                  value: student.parentName ?? 'Not available',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  icon: Icons.phone,
                  label: 'Phone Number',
                  value: student.parentPhone ?? 'Not available',
                ),
                const SizedBox(height: 32),
                
                // Attendance Summary (Mock data)
                Text(
                  'Attendance Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        label: 'Present',
                        value: '45',
                        color: Colors.green,
                        icon: Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        label: 'Absent',
                        value: '3',
                        color: Colors.red,
                        icon: Icons.cancel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        label: 'Rate',
                        value: '93%',
                        color: Colors.blue,
                        icon: Icons.trending_up,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: student.parentPhone != null
                        ? () {
                            Navigator.pop(context);
                            _callParent(context, student);
                          }
                        : null,
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Parent'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  List<Student> _sortStudents(List<Student> students) {
    final sortedList = List<Student>.from(students);
    
    switch (_sortOption) {
      case SortOption.nameAsc:
        sortedList.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        sortedList.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.gradeAsc:
        sortedList.sort((a, b) {
          final gradeA = a.grade ?? '';
          final gradeB = b.grade ?? '';
          return gradeA.compareTo(gradeB);
        });
        break;
      case SortOption.gradeDesc:
        sortedList.sort((a, b) {
          final gradeA = a.grade ?? '';
          final gradeB = b.grade ?? '';
          return gradeB.compareTo(gradeA);
        });
        break;
    }
    
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routesAsync = ref.watch(studentRoutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              routesAsync.whenData((routes) {
                _showFilterOptions(context, routes);
              });
            },
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search students or parents...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Active Filters Chips
          if (_selectedRouteId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Filters:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  routesAsync.when(
                    data: (routes) {
                      final route = routes.firstWhere(
                        (r) => r.id == _selectedRouteId,
                        orElse: () => routes.first,
                      );
                      return Chip(
                        label: Text(route.name),
                        onDeleted: () => setState(() => _selectedRouteId = null),
                        deleteIcon: const Icon(Icons.close, size: 18),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          
          // Student List
          Expanded(
            child: routesAsync.when(
              data: (routes) {
                if (routes.isEmpty) {
                  return const Center(
                    child: Text('No routes assigned'),
                  );
                }

                // Collect students with route info
                final studentsWithRoutes = <Map<String, dynamic>>[];
                for (final route in routes) {
                  if (_selectedRouteId == null || route.id == _selectedRouteId) {
                    for (final student in route.students) {
                      studentsWithRoutes.add({
                        'student': student,
                        'route': route,
                      });
                    }
                  }
                }
                
                // Filter students based on search query
                final filteredStudents = _searchQuery.isEmpty
                    ? studentsWithRoutes
                    : studentsWithRoutes.where((item) {
                        final student = item['student'] as Student;
                        return student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                               (student.parentName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                      }).toList();

                if (filteredStudents.isEmpty) {
                  return const Center(
                    child: Text('No students found'),
                  );
                }

                // Sort students
                final students = filteredStudents.map((item) => item['student'] as Student).toList();
                final sortedStudents = _sortStudents(students);
                
                // Rebuild with sorted order
                final sortedWithRoutes = sortedStudents.map((student) {
                  return filteredStudents.firstWhere(
                    (item) => (item['student'] as Student).id == student.id,
                  );
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedWithRoutes.length,
                  itemBuilder: (context, index) {
                    final item = sortedWithRoutes[index];
                    final student = item['student'] as Student;
                    final route = item['route'] as models.Route;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            student.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.route, size: 14, color: Colors.blue[700]),
                                const SizedBox(width: 4),
                                Text(
                                  route.name,
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (student.grade != null)
                              Text(student.grade!),
                            if (student.parentName != null)
                              Text(
                                'Parent: ${student.parentName}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (student.parentPhone != null)
                              IconButton(
                                icon: const Icon(Icons.phone),
                                color: Colors.green,
                                onPressed: () => _callParent(context, student),
                                tooltip: 'Call Parent',
                              ),
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () => _showStudentDetails(context, student, route.name),
                              tooltip: 'View Details',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
