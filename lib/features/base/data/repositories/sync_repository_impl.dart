import '../../domain/repositories/sync_repository.dart';

class SyncRepositoryImpl implements ISyncRepository {
  SyncRepositoryImpl();

  @override
  Future<bool> syncData(String key, dynamic data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  SyncStatus get status => SyncStatus.idle;
}
