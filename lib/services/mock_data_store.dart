// Mock data store for simulating backend data

import '../models/user.dart';
import '../models/route.dart';
import '../models/student.dart';
import '../models/trip.dart';
import '../models/attendance_record.dart';

class MockDataStore {
  // In-memory storage
  static final Map<String, dynamic> _store = {};

  // Pre-populated mock users (drivers)
  static final List<User> mockUsers = [
    User(
      id: 'driver_1',
      phone: '9876543210',
      role: UserRole.DRIVER,
      token: 'mock_token_driver_1',
    ),
    User(
      id: 'driver_2',
      phone: '9876543211',
      role: UserRole.DRIVER,
      token: 'mock_token_driver_2',
    ),
    User(
      id: 'driver_3',
      phone: '9876543212',
      role: UserRole.DRIVER,
      token: 'mock_token_driver_3',
    ),
    User(
      id: 'driver_4',
      phone: '9876543213',
      role: UserRole.DRIVER,
      token: 'mock_token_driver_4',
    ),
    User(
      id: 'driver_5',
      phone: '9876543214',
      role: UserRole.DRIVER,
      token: 'mock_token_driver_5',
    ),
  ];

  // Pre-populated mock students
  static final List<Student> mockStudents = [
    // Route 1 students (5 students)
    Student(id: 'student_1', name: 'Aarav Kumar', assignedRouteId: 'route_1', parentName: 'Rajesh Kumar', parentPhone: '+91 98765 43210', grade: 'Grade 5'),
    Student(id: 'student_2', name: 'Diya Sharma', assignedRouteId: 'route_1', parentName: 'Priya Sharma', parentPhone: '+91 98765 43211', grade: 'Grade 4'),
    Student(id: 'student_3', name: 'Arjun Patel', assignedRouteId: 'route_1', parentName: 'Amit Patel', parentPhone: '+91 98765 43212', grade: 'Grade 6'),
    Student(id: 'student_4', name: 'Ananya Singh', assignedRouteId: 'route_1', parentName: 'Sunita Singh', parentPhone: '+91 98765 43213', grade: 'Grade 5'),
    Student(id: 'student_5', name: 'Vihaan Reddy', assignedRouteId: 'route_1', parentName: 'Venkat Reddy', parentPhone: '+91 98765 43214', grade: 'Grade 7'),
    
    // Route 2 students (4 students)
    Student(id: 'student_6', name: 'Aisha Khan', assignedRouteId: 'route_2', parentName: 'Fatima Khan', parentPhone: '+91 98765 43215', grade: 'Grade 4'),
    Student(id: 'student_7', name: 'Rohan Gupta', assignedRouteId: 'route_2', parentName: 'Suresh Gupta', parentPhone: '+91 98765 43216', grade: 'Grade 6'),
    Student(id: 'student_8', name: 'Saanvi Mehta', assignedRouteId: 'route_2', parentName: 'Neha Mehta', parentPhone: '+91 98765 43217', grade: 'Grade 5'),
    Student(id: 'student_9', name: 'Kabir Joshi', assignedRouteId: 'route_2', parentName: 'Vikram Joshi', parentPhone: '+91 98765 43218', grade: 'Grade 7'),
    
    // Route 3 students (3 students)
    Student(id: 'student_10', name: 'Myra Desai', assignedRouteId: 'route_3', parentName: 'Anjali Desai', parentPhone: '+91 98765 43219', grade: 'Grade 4'),
    Student(id: 'student_11', name: 'Advait Nair', assignedRouteId: 'route_3', parentName: 'Ramesh Nair', parentPhone: '+91 98765 43220', grade: 'Grade 6'),
    Student(id: 'student_12', name: 'Kiara Iyer', assignedRouteId: 'route_3', parentName: 'Lakshmi Iyer', parentPhone: '+91 98765 43221', grade: 'Grade 5'),
    
    // Route 4 students (6 students)
    Student(id: 'student_13', name: 'Reyansh Verma', assignedRouteId: 'route_4', parentName: 'Anil Verma', parentPhone: '+91 98765 43222', grade: 'Grade 7'),
    Student(id: 'student_14', name: 'Aadhya Pillai', assignedRouteId: 'route_4', parentName: 'Meera Pillai', parentPhone: '+91 98765 43223', grade: 'Grade 4'),
    Student(id: 'student_15', name: 'Ishaan Rao', assignedRouteId: 'route_4', parentName: 'Krishna Rao', parentPhone: '+91 98765 43224', grade: 'Grade 6'),
    Student(id: 'student_16', name: 'Navya Menon', assignedRouteId: 'route_4', parentName: 'Divya Menon', parentPhone: '+91 98765 43225', grade: 'Grade 5'),
    Student(id: 'student_17', name: 'Vivaan Bhat', assignedRouteId: 'route_4', parentName: 'Sanjay Bhat', parentPhone: '+91 98765 43226', grade: 'Grade 7'),
    Student(id: 'student_18', name: 'Sara Kapoor', assignedRouteId: 'route_4', parentName: 'Ritu Kapoor', parentPhone: '+91 98765 43227', grade: 'Grade 4'),
    
    // Route 5 students (2 students)
    Student(id: 'student_19', name: 'Aditya Malhotra', assignedRouteId: 'route_5', parentName: 'Rahul Malhotra', parentPhone: '+91 98765 43228', grade: 'Grade 6'),
    Student(id: 'student_20', name: 'Zara Chopra', assignedRouteId: 'route_5', parentName: 'Pooja Chopra', parentPhone: '+91 98765 43229', grade: 'Grade 5'),
    
    // Route 6 students (4 students)
    Student(id: 'student_21', name: 'Ayaan Sinha', assignedRouteId: 'route_6', parentName: 'Deepak Sinha', parentPhone: '+91 98765 43230', grade: 'Grade 7'),
    Student(id: 'student_22', name: 'Pari Banerjee', assignedRouteId: 'route_6', parentName: 'Soma Banerjee', parentPhone: '+91 98765 43231', grade: 'Grade 4'),
    Student(id: 'student_23', name: 'Dhruv Agarwal', assignedRouteId: 'route_6', parentName: 'Manish Agarwal', parentPhone: '+91 98765 43232', grade: 'Grade 6'),
    Student(id: 'student_24', name: 'Riya Saxena', assignedRouteId: 'route_6', parentName: 'Kavita Saxena', parentPhone: '+91 98765 43233', grade: 'Grade 5'),
    
    // Route 7 students (5 students)
    Student(id: 'student_25', name: 'Shaurya Mishra', assignedRouteId: 'route_7', parentName: 'Alok Mishra', parentPhone: '+91 98765 43234', grade: 'Grade 7'),
    Student(id: 'student_26', name: 'Anvi Pandey', assignedRouteId: 'route_7', parentName: 'Rekha Pandey', parentPhone: '+91 98765 43235', grade: 'Grade 4'),
    Student(id: 'student_27', name: 'Atharv Tiwari', assignedRouteId: 'route_7', parentName: 'Manoj Tiwari', parentPhone: '+91 98765 43236', grade: 'Grade 6'),
    Student(id: 'student_28', name: 'Ira Dubey', assignedRouteId: 'route_7', parentName: 'Nisha Dubey', parentPhone: '+91 98765 43237', grade: 'Grade 5'),
    Student(id: 'student_29', name: 'Pranav Jain', assignedRouteId: 'route_7', parentName: 'Ashok Jain', parentPhone: '+91 98765 43238', grade: 'Grade 7'),
    
    // Route 8 students (3 students)
    Student(id: 'student_30', name: 'Mira Bhatt', assignedRouteId: 'route_8', parentName: 'Geeta Bhatt', parentPhone: '+91 98765 43239', grade: 'Grade 4'),
    Student(id: 'student_31', name: 'Arnav Kulkarni', assignedRouteId: 'route_8', parentName: 'Prakash Kulkarni', parentPhone: '+91 98765 43240', grade: 'Grade 6'),
    Student(id: 'student_32', name: 'Tara Shetty', assignedRouteId: 'route_8', parentName: 'Uma Shetty', parentPhone: '+91 98765 43241', grade: 'Grade 5'),
    
    // Route 9 students (4 students)
    Student(id: 'student_33', name: 'Yash Thakur', assignedRouteId: 'route_9', parentName: 'Dinesh Thakur', parentPhone: '+91 98765 43242', grade: 'Grade 7'),
    Student(id: 'student_34', name: 'Nitya Ghosh', assignedRouteId: 'route_9', parentName: 'Rina Ghosh', parentPhone: '+91 98765 43243', grade: 'Grade 4'),
    Student(id: 'student_35', name: 'Kian Das', assignedRouteId: 'route_9', parentName: 'Subir Das', parentPhone: '+91 98765 43244', grade: 'Grade 6'),
    Student(id: 'student_36', name: 'Aanya Bose', assignedRouteId: 'route_9', parentName: 'Monika Bose', parentPhone: '+91 98765 43245', grade: 'Grade 5'),
    
    // Route 10 students (5 students)
    Student(id: 'student_37', name: 'Rudra Chatterjee', assignedRouteId: 'route_10', parentName: 'Tapas Chatterjee', parentPhone: '+91 98765 43246', grade: 'Grade 7'),
    Student(id: 'student_38', name: 'Shanaya Roy', assignedRouteId: 'route_10', parentName: 'Anita Roy', parentPhone: '+91 98765 43247', grade: 'Grade 4'),
    Student(id: 'student_39', name: 'Aayansh Sen', assignedRouteId: 'route_10', parentName: 'Biswajit Sen', parentPhone: '+91 98765 43248', grade: 'Grade 6'),
    Student(id: 'student_40', name: 'Kavya Mukherjee', assignedRouteId: 'route_10', parentName: 'Sujata Mukherjee', parentPhone: '+91 98765 43249', grade: 'Grade 5'),
    Student(id: 'student_41', name: 'Shivansh Dutta', assignedRouteId: 'route_10', parentName: 'Ranjan Dutta', parentPhone: '+91 98765 43250', grade: 'Grade 7'),
    
    // Route 11 students (3 students)
    Student(id: 'student_42', name: 'Avni Bhardwaj', assignedRouteId: 'route_11', parentName: 'Sandeep Bhardwaj', parentPhone: '+91 98765 43251', grade: 'Grade 4'),
    Student(id: 'student_43', name: 'Lakshya Kohli', assignedRouteId: 'route_11', parentName: 'Vikas Kohli', parentPhone: '+91 98765 43252', grade: 'Grade 6'),
    Student(id: 'student_44', name: 'Prisha Arora', assignedRouteId: 'route_11', parentName: 'Simran Arora', parentPhone: '+91 98765 43253', grade: 'Grade 5'),
    
    // Route 12 students (2 students)
    Student(id: 'student_45', name: 'Sai Sethi', assignedRouteId: 'route_12', parentName: 'Karan Sethi', parentPhone: '+91 98765 43254', grade: 'Grade 7'),
    Student(id: 'student_46', name: 'Aarohi Khanna', assignedRouteId: 'route_12', parentName: 'Preeti Khanna', parentPhone: '+91 98765 43255', grade: 'Grade 4'),
  ];

  // Pre-populated mock routes with driver assignments
  static final List<Route> mockRoutes = [
    Route(
      id: 'route_1',
      name: 'North Campus - Morning',
      students: mockStudents.where((s) => s.assignedRouteId == 'route_1').toList(),
    ),
    Route(
      id: 'route_2',
      name: 'South Campus - Morning',
      students: mockStudents.where((s) => s.assignedRouteId == 'route_2').toList(),
    ),
    Route(
      id: 'route_3',
      name: 'East Campus - Morning',
      students: mockStudents.where((s) => s.assignedRouteId == 'route_3').toList(),
    ),
    Route(
      id: 'route_4',
      name: 'West Campus - Morning',
      students: mockStudents.where((s) => s.assignedRouteId == 'route_4').toList(),
    ),
    Route(
      id: 'route_5',
      name: 'Central District',
      students: mockStudents.where((s) => s.assignedRouteId == 'route_5').toList(),
    ),
    Route(
      id: 'route_6',
      name: 'Riverside Route',
      students: mockStudents.where((s) => s.assignedRouteId == 'route_6').toList(),
    ),
    Route(
      id: 'route_7',
      name: 'Hillside Express',
      students: mockStudents.where((s) => s.assignedRouteId == 'route_7').toList(),
    ),
    Route(
      id: 'route_8',
      name: 'Downtown Loop',
      students: mockStudents.where((s) => s.assignedRouteId == 'route_8').toList(),
    ),
    Route(
      id: 'route_9',
      name: 'Suburban Circuit',
      students: mockStudents.where((s) => s.assignedRouteId == 'route_9').toList(),
    ),
    Route(
      id: 'route_10',
      name: 'Garden District',
      students: mockStudents.where((s) => s.assignedRouteId == 'route_10').toList(),
    ),
    Route(
      id: 'route_11',
      name: 'Industrial Area',
      students: mockStudents.where((s) => s.assignedRouteId == 'route_11').toList(),
    ),
    Route(
      id: 'route_12',
      name: 'Tech Park Shuttle',
      students: mockStudents.where((s) => s.assignedRouteId == 'route_12').toList(),
    ),
  ];

  // Driver to route assignments
  static final Map<String, List<String>> driverRouteAssignments = {
    'driver_1': ['route_1', 'route_2', 'route_3'],
    'driver_2': ['route_4', 'route_5'],
    'driver_3': ['route_6', 'route_7', 'route_8'],
    'driver_4': ['route_9', 'route_10'],
    'driver_5': ['route_11', 'route_12'],
  };

  // Valid OTP for all mock users (for testing)
  static const String validOtp = '123456';

  // Helper method to simulate async API calls with delay
  static Future<T> simulateApiCall<T>(T Function() operation) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return operation();
  }

  // Storage operations
  static void set(String key, dynamic value) {
    _store[key] = value;
  }

  static T? get<T>(String key) {
    return _store[key] as T?;
  }

  static void remove(String key) {
    _store.remove(key);
  }

  static void clear() {
    _store.clear();
  }

  static bool containsKey(String key) {
    return _store.containsKey(key);
  }
}
