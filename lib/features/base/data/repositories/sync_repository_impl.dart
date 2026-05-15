import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_datasource.dart';

class SyncRepositoryImpl implements ISyncRepository {
  final ISyncDataSource _dataSource;

  SyncRepositoryImpl(this._dataSource);

  @override
  Future<bool> syncData(String key, dynamic data) async {
    try {
      return await _dataSource.upload(key, data);
    } catch (e) {
      print('Sync failed: $e');
      return false;
    }
  }

  @override
  SyncStatus get status => _dataSource.status;
}
