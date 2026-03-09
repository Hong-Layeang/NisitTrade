import '../models/student.dart';

abstract class StudentRepository {
  Future<List<Student>> getStudents();
}

class StudentRepositoryImpl implements StudentRepository {
  @override
  Future<List<Student>> getStudents() async {
    // TODO: Implement student API integration when backend is ready
    throw UnimplementedError('StudentRepository not yet implemented. Awaiting backend API.');
  }
}
