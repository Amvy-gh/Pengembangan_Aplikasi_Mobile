import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_profile.dart';
import 'package:path/path.dart';
import '../screens/jadwal_perkuliahan.dart';
import '../screens/jadwal_kerja_kelompok.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init() {
    // Initialize FFI loader only on desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      // For desktop platforms, use FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // On mobile platforms (Android/iOS), the regular sqflite plugin will be used automatically
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('schedule.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    // Buka database yang ada atau buat baru jika belum ada
    return await openDatabase(
      path,
      version: 3, // Increment version number untuk menambahkan kolom user_id
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    // Upgrade ke versi 3: Tambahkan kolom user_id ke tabel schedules, team_schedules, dan selected_optimal_schedules
    if (oldVersion < 3) {
      try {
        // Periksa apakah kolom user_id sudah ada di tabel schedules
        final tableInfo = await db.rawQuery("PRAGMA table_info(schedules)");
        final hasUserId = tableInfo.any((column) => column['name'] == 'user_id');
        
        if (!hasUserId) {
          // Tambahkan kolom user_id ke tabel schedules
          await db.execute('ALTER TABLE schedules ADD COLUMN user_id TEXT');
          print('Added user_id column to schedules table');
        }
        
        // Periksa apakah kolom user_id sudah ada di tabel team_schedules
        final teamTableInfo = await db.rawQuery("PRAGMA table_info(team_schedules)");
        final hasTeamUserId = teamTableInfo.any((column) => column['name'] == 'user_id');
        
        if (!hasTeamUserId) {
          // Tambahkan kolom user_id ke tabel team_schedules
          await db.execute('ALTER TABLE team_schedules ADD COLUMN user_id TEXT');
          print('Added user_id column to team_schedules table');
        }
        
        // Periksa apakah kolom user_id sudah ada di tabel selected_optimal_schedules
        final optimalTableInfo = await db.rawQuery("PRAGMA table_info(selected_optimal_schedules)");
        final hasOptimalUserId = optimalTableInfo.any((column) => column['name'] == 'user_id');
        
        if (!hasOptimalUserId) {
          // Tambahkan kolom user_id ke tabel selected_optimal_schedules
          await db.execute('ALTER TABLE selected_optimal_schedules ADD COLUMN user_id TEXT');
          print('Added user_id column to selected_optimal_schedules table');
        }
      } catch (e) {
        print('Error adding user_id column: $e');
      }
    }
  
    if (oldVersion < 2) {
      // Add the new tables for version 2
      try {
        // Check if team_schedules table has the necessary columns
        final tableInfo = await db.rawQuery("PRAGMA table_info(team_schedules)");
        final hasStartTime = tableInfo.any((column) => column['name'] == 'start_time');
        final hasMataKuliah = tableInfo.any((column) => column['name'] == 'mata_kuliah');
        
        if (!hasStartTime) {
          // Add time columns to team_schedules
          await db.execute('ALTER TABLE team_schedules ADD COLUMN start_time TEXT');
          await db.execute('ALTER TABLE team_schedules ADD COLUMN end_time TEXT');
          print('Added start_time and end_time columns to team_schedules');
        }
        
        if (!hasMataKuliah) {
          // Add schedule data columns to team_schedules
          await db.execute('ALTER TABLE team_schedules ADD COLUMN mata_kuliah TEXT');
          await db.execute('ALTER TABLE team_schedules ADD COLUMN waktu TEXT');
          await db.execute('ALTER TABLE team_schedules ADD COLUMN ruangan TEXT');
          await db.execute('ALTER TABLE team_schedules ADD COLUMN dosen TEXT');
          await db.execute('ALTER TABLE team_schedules ADD COLUMN hari TEXT');
          print('Added schedule data columns to team_schedules');
          
          // Migrate existing data from schedules to team_schedules
          final teamSchedules = await db.query('team_schedules');
          for (var teamSchedule in teamSchedules) {
            final scheduleId = teamSchedule['schedule_id'] as int?;
            if (scheduleId != null) {
              final scheduleData = await db.query(
                'schedules',
                where: 'id = ?',
                whereArgs: [scheduleId],
              );
              
              if (scheduleData.isNotEmpty) {
                await db.update(
                  'team_schedules',
                  {
                    'mata_kuliah': scheduleData.first['mataKuliah'],
                    'waktu': scheduleData.first['waktu'],
                    'ruangan': scheduleData.first['ruangan'],
                    'dosen': scheduleData.first['dosen'],
                    'hari': scheduleData.first['hari'],
                  },
                  where: 'id = ?',
                  whereArgs: [teamSchedule['id']],
                );
              }
            }
          }
        }
        
        // Create the new tables for optimal schedules
        await db.execute('''
          CREATE TABLE IF NOT EXISTS selected_optimal_schedules(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            day TEXT NOT NULL,
            time TEXT NOT NULL,
            location TEXT NOT NULL,
            is_selected INTEGER DEFAULT 0
          )
        ''');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS optimal_schedule_members(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            optimal_schedule_id INTEGER NOT NULL,
            member_name TEXT NOT NULL,
            FOREIGN KEY (optimal_schedule_id) REFERENCES selected_optimal_schedules (id)
          )
        ''');
        
        print('Created new tables for optimal schedules');
      } catch (e) {
        print('Error during database upgrade: $e');
      }
    }
  }
  
  Future<void> _createDB(Database db, int version) async {
    // Create user profiles table
    await db.execute('''
      CREATE TABLE user_profiles(
        uid TEXT PRIMARY KEY,
        display_name TEXT,
        email TEXT,
        photo_url TEXT,
        phone_number TEXT,
        department TEXT,
        student_id TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mataKuliah TEXT NOT NULL,
        waktu TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        ruangan TEXT NOT NULL,
        dosen TEXT NOT NULL,
        hari TEXT NOT NULL,
        user_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE team_schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schedule_id INTEGER,
        start_time TEXT,
        end_time TEXT,
        mata_kuliah TEXT,
        waktu TEXT,
        ruangan TEXT,
        dosen TEXT,
        hari TEXT,
        user_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE team_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        team_schedule_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        FOREIGN KEY (team_schedule_id) REFERENCES team_schedules (id)
      )
    ''');
    
    await db.execute('''
      CREATE TABLE selected_optimal_schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        time TEXT NOT NULL,
        location TEXT NOT NULL,
        is_selected INTEGER DEFAULT 0,
        user_id TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE optimal_schedule_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        optimal_schedule_id INTEGER NOT NULL,
        member_name TEXT NOT NULL,
        FOREIGN KEY (optimal_schedule_id) REFERENCES selected_optimal_schedules (id)
      )
    ''');
  }

  // Schedule methods
  Future<int> insertSchedule(Schedule schedule, {String? userId}) async {
    final db = await instance.database;
    return await db.insert('schedules', {
      'mataKuliah': schedule.mataKuliah,
      'waktu': schedule.waktu,
      'startTime': schedule.startTime,
      'endTime': schedule.endTime,
      'ruangan': schedule.ruangan,
      'dosen': schedule.dosen,
      'hari': schedule.hari,
      'user_id': userId,
    });
  }

  // Tambahkan fungsi ini di class DatabaseHelper
  
  Future<int> updateSchedule(int id, Schedule schedule, {String? userId}) async {
    final db = await instance.database;
    return await db.update(
      'schedules',
      {
        'mataKuliah': schedule.mataKuliah,
        'waktu': schedule.waktu,
        'startTime': schedule.startTime,
        'endTime': schedule.endTime,
        'ruangan': schedule.ruangan,
        'dosen': schedule.dosen,
        'hari': schedule.hari,
        'user_id': userId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<int> deleteSchedule(int id) async {
    final db = await instance.database;
    return await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Modifikasi getAllSchedules untuk menyertakan ID dan filter berdasarkan user_id
  Future<List<Schedule>> getAllSchedules({String? userId}) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> schedules;
    
    if (userId != null) {
      // Filter jadwal berdasarkan user_id
      schedules = await db.query(
        'schedules',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } else {
      // Ambil semua jadwal jika userId tidak disediakan
      schedules = await db.query('schedules');
    }
    
    return schedules.map((map) => Schedule(
      id: map['id'] as int,
      mataKuliah: map['mataKuliah'] as String,
      waktu: map['waktu'] as String,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      ruangan: map['ruangan'] as String,
      dosen: map['dosen'] as String,
      hari: map['hari'] as String,
    )).toList();
  }

  // Team Schedule methods
  // This method is used for inserting team schedules without affecting the regular schedules table
  Future<int> insertTeamScheduleOnly(TeamSchedule teamSchedule, {String? userId}) async {
    final db = await instance.database;
  
    // Create a new entry in team_schedules table with all schedule data
    // This avoids creating an entry in the regular schedules table
    final teamScheduleId = await db.insert('team_schedules', {
      'mata_kuliah': teamSchedule.schedule.mataKuliah,
      'waktu': teamSchedule.schedule.waktu,
      'ruangan': teamSchedule.schedule.ruangan,
      'dosen': teamSchedule.schedule.dosen,
      'hari': teamSchedule.schedule.hari,
      'start_time': teamSchedule.startTime,
      'end_time': teamSchedule.endTime,
      'user_id': userId,
    });

    // Insert all team members
    for (var member in teamSchedule.members) {
      await db.insert('team_members', {
        'team_schedule_id': teamScheduleId,
        'name': member.name,
        'role': member.role,
      });
    }

    return teamScheduleId;
  }
  
  // Original method - kept for compatibility with existing code
  Future<int> insertTeamSchedule(TeamSchedule teamSchedule, {String? userId}) async {
    final db = await instance.database;
    final scheduleId = await insertSchedule(teamSchedule.schedule, userId: userId);
    
    final teamScheduleId = await db.insert('team_schedules', {
      'schedule_id': scheduleId,
      'start_time': teamSchedule.startTime,
      'end_time': teamSchedule.endTime,
      'user_id': userId,
    });

    for (var member in teamSchedule.members) {
      await db.insert('team_members', {
        'team_schedule_id': teamScheduleId,
        'name': member.name,
        'role': member.role,
      });
  }

  return teamSchedule.id ?? 0; // Provide a default value if id is null
}
  
// Method to update team schedules with proper handling of team members and available times
Future<int> updateTeamSchedule(TeamSchedule teamSchedule, {String? userId}) async {
  final db = await instance.database;
  
  if (teamSchedule.id == null) {
    throw Exception('Cannot update team schedule without an ID');
  }
  
  // Update the team_schedules table with all schedule data
  final rowsAffected = await db.update(
    'team_schedules',
    {
      'start_time': teamSchedule.startTime,
      'end_time': teamSchedule.endTime,
      'mata_kuliah': teamSchedule.schedule.mataKuliah,
      'waktu': teamSchedule.schedule.waktu,
      'ruangan': teamSchedule.schedule.ruangan,
      'dosen': teamSchedule.schedule.dosen,
      'hari': teamSchedule.schedule.hari,
      'user_id': userId,
    },
    where: 'id = ?',
    whereArgs: [teamSchedule.id],
  );
  
  // Delete existing member available times
  await db.delete(
    'member_available_times',
    where: 'team_member_id = ?',
    whereArgs: [teamSchedule.id],
  );
  
  // Delete existing team members
  await db.delete(
    'team_members',
    where: 'team_schedule_id = ?',
    whereArgs: [teamSchedule.id],
  );
  
  // Insert updated team members
  for (var member in teamSchedule.members) {
    await db.insert('team_members', {
      'team_schedule_id': teamSchedule.id,
      'name': member.name,
      'role': member.role,
    });
    
    // Insert available times for each member
    for (var time in member.availableTimes) {
      await db.insert('member_available_times', {
        'team_member_id': teamSchedule.id,
        'member_name': member.name,
        'available_time': time,
      });
    }
  }
  
  return teamSchedule.id ?? 0; // Provide a default value if id is null
}

  // This method deletes team schedules without affecting the schedules table
  Future<void> deleteTeamScheduleOnly(TeamSchedule teamSchedule) async {
    final db = await instance.database;

    // Delete team members first due to foreign key constraint
    await db.delete(
      'team_members',
      where: 'team_schedule_id = ?',
      whereArgs: [teamSchedule.id],
    );

    // Delete team schedule
    await db.delete(
      'team_schedules',
      where: 'id = ?',
      whereArgs: [teamSchedule.id],
    );

    // We don't delete the associated schedule to avoid affecting jadwal_perkuliahan
    // This means there will be some orphaned records in the schedules table,
    // but they won't affect the functionality of the app
  }
  
  // Original method - kept for compatibility with existing code
  Future<void> deleteTeamSchedule(TeamSchedule teamSchedule) async {
    final db = await instance.database;

    // Delete team members first due to foreign key constraint
    await db.delete(
      'team_members',
      where: 'team_schedule_id = ?',
      whereArgs: [teamSchedule.id],
    );

    // Delete team schedule
    await db.delete(
      'team_schedules',
      where: 'id = ?',
      whereArgs: [teamSchedule.id],
    );

    // Delete the associated schedule
    await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [teamSchedule.schedule.id],
    );
  }

  Future<void> deleteAllTeamSchedules() async {
    final db = await instance.database;
    await db.delete('team_schedules');
    await db.delete('team_members');
  }

  Future<List<TeamSchedule>> getAllTeamSchedules({String? userId}) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> teamSchedules;
    
    if (userId != null) {
      // Filter jadwal tim berdasarkan user_id
      teamSchedules = await db.query(
        'team_schedules',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } else {
      // Ambil semua jadwal tim jika userId tidak disediakan
      teamSchedules = await db.query('team_schedules');
    }
    
    List<TeamSchedule> result = [];

    for (var teamSchedule in teamSchedules) {
      final teamScheduleId = teamSchedule['id'] as int;
      final startTime = teamSchedule['start_time'] as String?;
      final endTime = teamSchedule['end_time'] as String?;
      
      // Get team members
      final memberData = await db.query(
        'team_members',
        where: 'team_schedule_id = ?',
        whereArgs: [teamScheduleId],
      );
      
      // Create a Schedule object from the team_schedules data
      final schedule = Schedule(
        id: teamScheduleId, // Use the team schedule ID as the schedule ID
        mataKuliah: teamSchedule['mata_kuliah'] as String? ?? '',
        waktu: teamSchedule['waktu'] as String? ?? '',
        startTime: startTime ?? '',
        endTime: endTime ?? '',
        ruangan: teamSchedule['ruangan'] as String? ?? '',
        dosen: teamSchedule['dosen'] as String? ?? '',
        hari: teamSchedule['hari'] as String? ?? '',
      );

      final members = memberData.map((member) => TeamMember(
        name: member['name'] as String,
        role: member['role'] as String,
      )).toList();

      result.add(TeamSchedule(
        id: teamScheduleId,
        schedule: schedule,
        members: members,
        startTime: startTime,
        endTime: endTime
      ));
    }

    return result;
  }
  
  // Methods for optimal schedules
  Future<int> saveOptimalSchedule(OptimalSchedule schedule, {bool isSelected = true, String? userId}) async {
    final db = await instance.database;
    
    // If this is selected, unselect all others first for this user
    if (isSelected && userId != null) {
      await db.update(
        'selected_optimal_schedules',
        {'is_selected': 0},
        where: 'is_selected = 1 AND user_id = ?',
        whereArgs: [userId]
      );
    } else if (isSelected) {
      // Jika tidak ada user_id, unselect semua
      await db.update(
        'selected_optimal_schedules',
        {'is_selected': 0},
        where: 'is_selected = 1'
      );
    }
    
    // Insert the optimal schedule with user_id if provided
    final scheduleData = {
      'day': schedule.day,
      'time': schedule.time,
      'location': schedule.location,
      'is_selected': isSelected ? 1 : 0,
    };
    
    // Tambahkan user_id jika disediakan
    if (userId != null) {
      scheduleData['user_id'] = userId;
    }
    
    final scheduleId = await db.insert('selected_optimal_schedules', scheduleData);
    
    // Insert all members
    for (var member in schedule.members) {
      await db.insert('optimal_schedule_members', {
        'optimal_schedule_id': scheduleId,
        'member_name': member,
      });
    }
    
    return scheduleId;
  }
  
  Future<List<OptimalSchedule>> getAllOptimalSchedules({String? userId}) async {
    final db = await instance.database;
    
    // Tambahkan filter user_id jika disediakan
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (userId != null) {
      whereClause = 'user_id = ?';
      whereArgs = [userId];
      print('Filtering optimal schedules for user_id: $userId');
    }
    
    final schedules = await db.query(
      'selected_optimal_schedules',
      where: whereClause,
      whereArgs: whereArgs
    );
    
    print('Found ${schedules.length} optimal schedules for user_id: $userId');
    
    List<OptimalSchedule> result = [];
    
    for (var schedule in schedules) {
      final scheduleId = schedule['id'] as int;
      
      final memberData = await db.query(
        'optimal_schedule_members',
        where: 'optimal_schedule_id = ?',
        whereArgs: [scheduleId],
      );
      
      final members = memberData.map((member) => member['member_name'] as String).toList();
      
      result.add(OptimalSchedule(
        id: scheduleId,
        day: schedule['day'] as String,
        time: schedule['time'] as String,
        location: schedule['location'] as String,
        members: members,
        isSelected: (schedule['is_selected'] as int) == 1,
      ));
    }
    
    return result;
  }
  
  // Get the currently selected optimal schedule (if any)
  Future<OptimalSchedule?> getSelectedOptimalSchedule({String? userId}) async {
    final db = await instance.database;
    
    // Tambahkan filter user_id jika disediakan
    String whereClause = 'is_selected = 1';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause += ' AND user_id = ?';
      whereArgs.add(userId);
    }
    
    final schedules = await db.query(
      'selected_optimal_schedules',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: 1
    );
    
    if (schedules.isEmpty) {
      return null;
    }
    
    final schedule = schedules.first;
    final scheduleId = schedule['id'] as int;
    
    final memberData = await db.query(
      'optimal_schedule_members',
      where: 'optimal_schedule_id = ?',
      whereArgs: [scheduleId],
    );
    
    final members = memberData.map((member) => member['member_name'] as String).toList();
    
    return OptimalSchedule(
      id: scheduleId,
      day: schedule['day'] as String,
      time: schedule['time'] as String,
      location: schedule['location'] as String,
      members: members,
      isSelected: true,
    );
  }
  
  // Delete the selected optimal schedule
  Future<int> deleteSelectedOptimalSchedule({String? userId}) async {
    final db = await instance.database;
    
    // Tambahkan filter user_id jika disediakan
    String whereClause = 'is_selected = 1';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause += ' AND user_id = ?';
      whereArgs.add(userId);
    }
    
    // Dapatkan ID jadwal yang akan dihapus
    final schedules = await db.query(
      'selected_optimal_schedules',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: 1
    );
    
    if (schedules.isEmpty) {
      return 0; // Tidak ada jadwal yang dihapus
    }
    
    final scheduleId = schedules.first['id'] as int;
    
    // Hapus anggota tim dari jadwal optimal
    await db.delete(
      'optimal_schedule_members',
      where: 'optimal_schedule_id = ?',
      whereArgs: [scheduleId],
    );
    
    // Hapus jadwal optimal
    return await db.delete(
      'selected_optimal_schedules',
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }
  
  // User Profile Methods
  
  // Save or update a user profile
  Future<int> saveUserProfile(UserProfile profile) async {
    final db = await instance.database;
    
    // Check if profile already exists
    final existingProfile = await db.query(
      'user_profiles',
      where: 'uid = ?',
      whereArgs: [profile.uid],
    );
    
    if (existingProfile.isNotEmpty) {
      // Update existing profile
      return await db.update(
        'user_profiles',
        profile.toMap(),
        where: 'uid = ?',
        whereArgs: [profile.uid],
      );
    } else {
      // Insert new profile
      return await db.insert('user_profiles', profile.toMap());
    }
  }
  
  // Get a user profile by uid
  Future<UserProfile?> getUserProfile(String uid) async {
    final db = await instance.database;
    
    final maps = await db.query(
      'user_profiles',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    
    return null;
  }
  
  // Delete a user profile
  Future<int> deleteUserProfile(String uid) async {
    final db = await instance.database;
    
    return await db.delete(
      'user_profiles',
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }
}