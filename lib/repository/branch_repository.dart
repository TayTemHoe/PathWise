import 'package:path_wise/model/branch.dart';
import '../services/firebase_service.dart';

class BranchRepository {
  final FirebaseService _firebaseService = FirebaseService();

  Future<List<BranchModel>> getBranchesByUniversity(String universityId) async {
    // This will now work instead of crashing
    final branch = await _firebaseService.getBranchesByUniversity(universityId);
    return branch;
  }
}