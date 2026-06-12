import 'package:postgres/postgres.dart';

class PostgresService {
  Connection? _connection;

  Future<Connection> _getConn() async {
    if (_connection == null || _connection!.isOpen == false) {
      _connection = await Connection.open(
        Endpoint(
          host: '10.0.2.2', // IP untuk emulator ke localhost
          database: 'jelita_db',
          username: 'postgres',
          password: 'your_password',
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );
    }
    return _connection!;
  }

  Future<Result> query(String sql, {Map<String, dynamic>? params}) async {
    final conn = await _getConn();
    return await conn.execute(Sql.named(sql), parameters: params);
  }

  Future<void> execute(String sql, {Map<String, dynamic>? params}) async {
    final conn = await _getConn();
    await conn.execute(Sql.named(sql), parameters: params);
  }

  Future<void> close() async {
    await _connection?.close();
  }
}
