import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../screens/jadwal_perkuliahan.dart';
import '../screens/jadwal_kerja_kelompok.dart';

// Model untuk User Profile
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String nim;
  final String prodi;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.nim,
    required this.prodi,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'nim': nim,
      'prodi': prodi,
    };
  }

  static UserProfile fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      nim: map['nim'],
      prodi: map['prodi'],
    );
  }
}

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
    _database = await _initDB('edutime.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    // Debug only: Uncomment to reset database during development
    /*
    try {
      await deleteDatabase(path);
      print('Deleted existing database to recreate with new schema');
    } catch (e) {
      print('No existing database to delete: $e');
    }
    */

    return await openDatabase(
      path,
      version: 3, // Increment version number to include user profiles
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
  
    if (oldVersion < 2) {
      // Add the tables for version 2
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
    
    if (oldVersion < 3) {
      // Add the user_profiles table for version 3
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_profiles(
            uid TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            nim TEXT NOT NULL,
            prodi TEXT NOT NULL
          )
        ''');
        print('Created user_profiles table');
      } catch (e) {
        print('Error creating user_profiles table: $e');
      }
    }
  }
  
  Future<void> _createDB(Database db, int version) async {
    // Create schedules tables
    await db.execute('''
      CREATE TABLE schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mataKuliah TEXT NOT NULL,
        waktu TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        ruangan TEXT NOT NULL,
        dosen TEXT NOT NULL,
        hari TEXT NOT NULL
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
        hari TEXT
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
        is_selected INTEGER DEFAULT 0
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
    
    // Create user profiles table
    await db.execute('''
      CREATE TABLE user_profiles(
        uid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        nim TEXT NOT NULL,
        prodi TEXT NOT NULL
      )
    ''');
  }

  // User Profile Methods
  Future<int> saveUserProfile(UserProfile profile) async {
    final db = await instance.database;
    
    // Check if user exists
    final existingUser = await db.query(
      'user_profiles',
      where: 'uid = ?',
      whereArgs: [profile.uid],
    );

    if (existingUser.isNotEmpty) {
      // Update existing user
      return await db.update(
        'user_profiles',
        profile.toMap(),
        where: 'uid = ?',
        whereArgs: [profile.uid],
      );
    } else {
      // Insert new user
      return await db.insert('user_profiles', profile.toMap());
    }
  }

  // Get user profile by uid
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

  // Update user profile
  Future<int> updateUserProfile(UserProfile profile) async {
    final db = await instance.database;
    return await db.update(
      'user_profiles',
      profile.toMap(),
      where: 'uid = ?',
      whereArgs: [profile.uid],
    );
  }

  // Schedule methods
  Future<int> insertSchedule(Schedule schedule) async {
    final db = await instance.database;
    return await db.insert('schedules', {
      'mataKuliah': schedule.mataKuliah,
      'waktu': schedule.waktu,
      'startTime': schedule.startTime,
      'endTime': schedule.endTime,
      'ruangan': schedule.ruangan,
      'dosen': schedule.dosen,
      'hari': schedule.hari,
    });
  }

  // Tambahkan fungsi ini di class DatabaseHelper
  
  Future<int> updateSchedule(int id, Schedule schedule) async {
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
  
  // Modifikasi getAllSchedules untuk menyertakan ID
  Future<List<Schedule>> getAllSchedules() async {
    final db = await instance.database;
    final result = await db.query('schedules');
    return result.map((json) => Schedule(
      id: json['id'] as int,
      mataKuliah: json['mataKuliah'] as String,
      waktu: json['waktu'] as String,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      ruangan: json['ruangan'] as String,
      dosen: json['dosen'] as String,
      hari: json['hari'] as String,
    )).toList();
  }

  // Team Schedule methods
  // This method is used for inserting team schedules without affecting the regular schedules table
  Future<int> insertTeamScheduleOnly(TeamSchedule teamSchedule) async {
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
  Future<int> insertTeamSchedule(TeamSchedule teamSchedule) async {
    final db = await instance.database;
    final scheduleId = await insertSchedule(teamSchedule.schedule);
    
    final teamScheduleId = await db.insert('team_schedules', {
      'schedule_id': scheduleId,
      'start_time': teamSchedule.startTime,
      'end_time': teamSchedule.endTime,
    });

    for (var member in teamSchedule.members) {
      await db.insert('team_members', {
        'team_schedule_id': teamScheduleId,
        'name': member.name,
        'role': member.role,
      });
    }

    return teamScheduleId;
  }

  // This method updates team schedules without affecting the regular schedules table
  Future<int> updateTeamScheduleOnly(TeamSchedule teamSchedule) async {
    final db = await instance.database;
  
    // Update the team schedule with all schedule data directly in team_schedules table
    await db.update(
      'team_schedules',
      {
        'start_time': teamSchedule.startTime,
        'end_time': teamSchedule.endTime,
        'mata_kuliah': teamSchedule.schedule.mataKuliah,
        'waktu': teamSchedule.schedule.waktu,
        'ruangan': teamSchedule.schedule.ruangan,
        'dosen': teamSchedule.schedule.dosen,
        'hari': teamSchedule.schedule.hari,
      },
      where: 'id = ?',
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
    }

    return teamSchedule.id ?? 0; // Provide a default value if id is null
  }
  
  // Original method - kept for compatibility with existing code
  Future<int> updateTeamSchedule(TeamSchedule teamSchedule) async {
    final db = await instance.database;
    
    // Update the schedule first
    await db.update(
      'schedules',
      {
        'mataKuliah': teamSchedule.schedule.mataKuliah,
        'waktu': teamSchedule.schedule.waktu,
        'ruangan': teamSchedule.schedule.ruangan,
        'dosen': teamSchedule.schedule.dosen,
        'hari': teamSchedule.schedule.hari,
      },
      where: 'id = ?',
      whereArgs: [teamSchedule.schedule.id],
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

  Future<List<TeamSchedule>> getAllTeamSchedules() async {
    final db = await instance.database;
    final teamSchedules = await db.query('team_schedules');
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
  Future<int> saveOptimalSchedule(OptimalSchedule schedule, {bool isSelected = true}) async {
    final db = await instance.database;
    
    // If this is selected, unselect all others first
    if (isSelected) {
      await db.update(
        'selected_optimal_schedules',
        {'is_selected': 0},
        where: 'is_selected = 1'
      );
    }
    
    // Insert the optimal schedule
    final scheduleId = await db.insert('selected_optimal_schedules', {
      'day': schedule.day,
      'time': schedule.time,
      'location': schedule.location,
      'is_selected': isSelected ? 1 : 0,
    });
    
    // Insert all members
    for (var member in schedule.members) {
      await db.insert('optimal_schedule_members', {
        'optimal_schedule_id': scheduleId,
        'member_name': member,
      });
    }
    
    return scheduleId;
  }
  
  Future<List<OptimalSchedule>> getAllOptimalSchedules() async {
    final db = await instance.database;
    final schedules = await db.query('selected_optimal_schedules');
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
  
  Future<OptimalSchedule?> getSelectedOptimalSchedule() async {
    final db = await instance.database;
    final schedules = await db.query(
      'selected_optimal_schedules',
      where: 'is_selected = 1',
      limit: 1,
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
}