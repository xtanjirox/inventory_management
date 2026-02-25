import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _database;

  AppDatabase._internal();

  static AppDatabase get instance {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventory.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id           TEXT PRIMARY KEY,
        name         TEXT NOT NULL,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL,
        deleted_at   INTEGER,
        is_synced    INTEGER NOT NULL DEFAULT 0,
        remote_id    TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE warehouses (
        id           TEXT PRIMARY KEY,
        name         TEXT NOT NULL,
        location     TEXT NOT NULL,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL,
        deleted_at   INTEGER,
        is_synced    INTEGER NOT NULL DEFAULT 0,
        remote_id    TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id                  TEXT PRIMARY KEY,
        name                TEXT NOT NULL,
        description         TEXT NOT NULL DEFAULT '',
        category_id         TEXT NOT NULL,
        warehouse_id        TEXT NOT NULL,
        sku                 TEXT NOT NULL UNIQUE,
        price               REAL NOT NULL DEFAULT 0.0,
        stock               INTEGER NOT NULL DEFAULT 0,
        low_stock_threshold INTEGER NOT NULL DEFAULT 10,
        supplier            TEXT NOT NULL DEFAULT '',
        image_url           TEXT,
        image_path          TEXT,
        variants_json       TEXT,
        created_at          INTEGER NOT NULL,
        updated_at          INTEGER NOT NULL,
        deleted_at          INTEGER,
        is_synced           INTEGER NOT NULL DEFAULT 0,
        remote_id           TEXT,
        FOREIGN KEY (category_id)  REFERENCES categories(id),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_products_category ON products(category_id)');
    await db.execute(
        'CREATE INDEX idx_products_warehouse ON products(warehouse_id)');
    await db.execute(
        'CREATE INDEX idx_products_unsynced ON products(is_synced) WHERE is_synced = 0');

    await db.execute('''
      CREATE TABLE users (
        id           TEXT PRIMARY KEY,
        name         TEXT NOT NULL,
        email        TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        plan         TEXT NOT NULL DEFAULT 'normal',
        currency     TEXT NOT NULL DEFAULT 'USD',
        language     TEXT NOT NULL DEFAULT 'en',
        avatar_url   TEXT,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE local_settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE activities (
        id              TEXT PRIMARY KEY,
        type            TEXT NOT NULL,
        product_id      TEXT NOT NULL,
        product_name    TEXT NOT NULL,
        quantity_change INTEGER,
        note            TEXT,
        user_id         TEXT NOT NULL,
        timestamp       INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_activities_timestamp ON activities(timestamp DESC)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute(
          'ALTER TABLE products ADD COLUMN image_path TEXT');
      await db.execute(
          'ALTER TABLE products ADD COLUMN variants_json TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS activities (
          id              TEXT PRIMARY KEY,
          type            TEXT NOT NULL,
          product_id      TEXT NOT NULL,
          product_name    TEXT NOT NULL,
          quantity_change INTEGER,
          note            TEXT,
          user_id         TEXT NOT NULL,
          timestamp       INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id           TEXT PRIMARY KEY,
          name         TEXT NOT NULL,
          email        TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          plan         TEXT NOT NULL DEFAULT 'normal',
          currency     TEXT NOT NULL DEFAULT 'USD',
          language     TEXT NOT NULL DEFAULT 'en',
          avatar_url   TEXT,
          created_at   INTEGER NOT NULL,
          updated_at   INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_settings (
          key   TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
