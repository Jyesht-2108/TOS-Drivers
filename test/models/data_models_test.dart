import 'package:flutter_test/flutter_test.dart';
import 'package:tos_driver_app/models/user.dart';
import 'package:tos_driver_app/models/student.dart';
import 'package:tos_driver_app/models/route.dart';
import 'package:tos_driver_app/models/trip.dart';
import 'package:tos_driver_app/models/attendance_record.dart';

void main() {
  group('User Model', () {
    test('toJson/fromJson round-trip preserves data', () {
      final user = User(
        id: 'user123',
        phone: '1234567890',
        role: UserRole.DRIVER,
        token: 'token123',
      );

      final json = user.toJson();
      final restored = User.fromJson(json);

      expect(restored.id, user.id);
      expect(restored.phone, user.phone);
      expect(restored.role, user.role);
      expect(restored.token, user.token);
    });

    test('UserRole enum converts to/from JSON', () {
      final role = UserRole.DRIVER;
      final json = role.toJson();
      final restored = UserRole.fromJson(json);

      expect(restored, role);
      expect(json, 'DRIVER');
    });
  });

  group('Student Model', () {
    test('toJson/fromJson round-trip preserves data', () {
      final student = Student(
        id: 'student123',
        name: 'John Doe',
        assignedRouteId: 'route123',
      );

      final json = student.toJson();
      final restored = Student.fromJson(json);

      expect(restored.id, student.id);
      expect(restored.name, student.name);
      expect(restored.assignedRouteId, student.assignedRouteId);
    });
  });

  group('Route Model', () {
    test('toJson/fromJson round-trip preserves data', () {
      final route = Route(
        id: 'route123',
        name: 'Route A',
        students: [
          Student(
            id: 'student1',
            name: 'Alice',
            assignedRouteId: 'route123',
          ),
          Student(
            id: 'student2',
            name: 'Bob',
            assignedRouteId: 'route123',
          ),
        ],
      );

      final json = route.toJson();
      final restored = Route.fromJson(json);

      expect(restored.id, route.id);
      expect(restored.name, route.name);
      expect(restored.students.length, route.students.length);
      expect(restored.students[0].id, route.students[0].id);
      expect(restored.students[0].name, route.students[0].name);
      expect(restored.students[1].id, route.students[1].id);
      expect(restored.students[1].name, route.students[1].name);
    });

    test('toJson/fromJson works with empty students list', () {
      final route = Route(
        id: 'route123',
        name: 'Empty Route',
        students: [],
      );

      final json = route.toJson();
      final restored = Route.fromJson(json);

      expect(restored.id, route.id);
      expect(restored.name, route.name);
      expect(restored.students.length, 0);
    });
  });

  group('Trip Model', () {
    test('toJson/fromJson round-trip preserves data with endTime', () {
      final startTime = DateTime(2024, 1, 15, 8, 30);
      final endTime = DateTime(2024, 1, 15, 9, 30);
      
      final trip = Trip(
        id: 'trip123',
        routeId: 'route123',
        tripType: TripType.PICKUP,
        status: TripStatus.ENDED,
        startTime: startTime,
        endTime: endTime,
      );

      final json = trip.toJson();
      final restored = Trip.fromJson(json);

      expect(restored.id, trip.id);
      expect(restored.routeId, trip.routeId);
      expect(restored.tripType, trip.tripType);
      expect(restored.status, trip.status);
      expect(restored.startTime, trip.startTime);
      expect(restored.endTime, trip.endTime);
    });

    test('toJson/fromJson round-trip preserves data without endTime', () {
      final startTime = DateTime(2024, 1, 15, 8, 30);
      
      final trip = Trip(
        id: 'trip123',
        routeId: 'route123',
        tripType: TripType.DROP,
        status: TripStatus.ACTIVE,
        startTime: startTime,
        endTime: null,
      );

      final json = trip.toJson();
      final restored = Trip.fromJson(json);

      expect(restored.id, trip.id);
      expect(restored.routeId, trip.routeId);
      expect(restored.tripType, trip.tripType);
      expect(restored.status, trip.status);
      expect(restored.startTime, trip.startTime);
      expect(restored.endTime, isNull);
    });

    test('TripType enum converts to/from JSON', () {
      expect(TripType.PICKUP.toJson(), 'PICKUP');
      expect(TripType.DROP.toJson(), 'DROP');
      expect(TripType.fromJson('PICKUP'), TripType.PICKUP);
      expect(TripType.fromJson('DROP'), TripType.DROP);
    });

    test('TripStatus enum converts to/from JSON', () {
      expect(TripStatus.ACTIVE.toJson(), 'ACTIVE');
      expect(TripStatus.ENDED.toJson(), 'ENDED');
      expect(TripStatus.fromJson('ACTIVE'), TripStatus.ACTIVE);
      expect(TripStatus.fromJson('ENDED'), TripStatus.ENDED);
    });
  });

  group('AttendanceRecord Model', () {
    test('toJson/fromJson round-trip preserves data with markedAt', () {
      final markedAt = DateTime(2024, 1, 15, 8, 45);
      
      final record = AttendanceRecord(
        studentId: 'student123',
        tripId: 'trip123',
        status: AttendanceStatus.PRESENT,
        isLocked: true,
        markedAt: markedAt,
      );

      final json = record.toJson();
      final restored = AttendanceRecord.fromJson(json);

      expect(restored.studentId, record.studentId);
      expect(restored.tripId, record.tripId);
      expect(restored.status, record.status);
      expect(restored.isLocked, record.isLocked);
      expect(restored.markedAt, record.markedAt);
    });

    test('toJson/fromJson round-trip preserves data without markedAt', () {
      final record = AttendanceRecord(
        studentId: 'student123',
        tripId: 'trip123',
        status: AttendanceStatus.UNMARKED,
        isLocked: false,
        markedAt: null,
      );

      final json = record.toJson();
      final restored = AttendanceRecord.fromJson(json);

      expect(restored.studentId, record.studentId);
      expect(restored.tripId, record.tripId);
      expect(restored.status, record.status);
      expect(restored.isLocked, record.isLocked);
      expect(restored.markedAt, isNull);
    });

    test('AttendanceStatus enum converts to/from JSON', () {
      expect(AttendanceStatus.PRESENT.toJson(), 'PRESENT');
      expect(AttendanceStatus.ABSENT.toJson(), 'ABSENT');
      expect(AttendanceStatus.UNMARKED.toJson(), 'UNMARKED');
      expect(AttendanceStatus.fromJson('PRESENT'), AttendanceStatus.PRESENT);
      expect(AttendanceStatus.fromJson('ABSENT'), AttendanceStatus.ABSENT);
      expect(AttendanceStatus.fromJson('UNMARKED'), AttendanceStatus.UNMARKED);
    });
  });
}
