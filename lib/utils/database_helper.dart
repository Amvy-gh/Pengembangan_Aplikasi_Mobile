import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
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
    
    // Delete existing database to recreate with new schema
    // This is a temporary solution for development - in production, you'd use migrations
    try {
      await deleteDatabase(path);
      print('Deleted existing database to recreate with new schema');
    } catch (e) {
      print('No existing database to delete: $e');
    }

    return await openDatabase(
      path,
      version: 2, // Increment version number
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Add the new tables for version 2
      try {
        // Check if team_schedules table has start_time and end_time columns
        final tableInfo = await db.rawQuery("PRAGMA table_info(team_schedules)");
        final hasStartTime = tableInfo.any((column) => column['name'] == 'start_time');
        
        if (!hasStartTime) {
          // Add the new columns to team_schedules
          await db.execute('ALTER TABLE team_schedules ADD COLUMN start_time TEXT');
          await db.execute('ALTER TABLE team_schedules ADD COLUMN end_time TEXT');
          print('Added start_time and end_time columns to team_schedules');
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
        schedule_id INTEGER NOT NULL,
        start_time TEXT,
        end_time TEXT,
        FOREIGN KEY (schedule_id) REFERENCES schedules (id)
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
    
    // First, insert the schedule data directly into the schedules table
    final scheduleId = await db.insert('schedules', {
      'mataKuliah': teamSchedule.schedule.mataKuliah,
      'waktu': teamSchedule.schedule.waktu,
      'startTime': teamSchedule.schedule.startTime,
      'endTime': teamSchedule.schedule.endTime,
      'ruangan': teamSchedule.schedule.ruangan,
      'dosen': teamSchedule.schedule.dosen,
      'hari': teamSchedule.schedule.hari,
    });
    
    // Then insert the team schedule with reference to the schedule
    final teamScheduleId = await db.insert('team_schedules', {
      'schedule_id': scheduleId,
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
    
    // Update the team schedule with start and end times
    await db.update(
      'team_schedules',
      {
        'start_time': teamSchedule.startTime,
        'end_time': teamSchedule.endTime,
      },
      where: 'id = ?',
      whereArgs: [teamSchedule.id],
    );
    
    // Update the schedule in the schedules table but only for this team schedule
    // This won't affect jadwal_perkuliahan.dart because we're only updating the schedule
    // that's linked to this specific team schedule
    await db.update(
      'schedules',
      {
        'mataKuliah': teamSchedule.schedule.mataKuliah,
        'waktu': teamSchedule.schedule.waktu,
        'startTime': teamSchedule.schedule.startTime,
        'endTime': teamSchedule.schedule.endTime,
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
      final scheduleId = teamSchedule['schedule_id'] as int;
      final teamScheduleId = teamSchedule['id'] as int;
      final startTime = teamSchedule['start_time'] as String?;
      final endTime = teamSchedule['end_time'] as String?;

      final scheduleData = await db.query(
        'schedules',
        where: 'id = ?',
        whereArgs: [scheduleId],
      );

      final memberData = await db.query(
        'team_members',
        where: 'team_schedule_id = ?',
        whereArgs: [teamScheduleId],
      );

      if (scheduleData.isNotEmpty) {
        final schedule = Schedule(
          id: scheduleData.first['id'] as int,
          mataKuliah: scheduleData.first['mataKuliah'] as String,
          waktu: scheduleData.first['waktu'] as String,
          startTime: scheduleData.first['startTime'] as String? ?? '',
          endTime: scheduleData.first['endTime'] as String? ?? '',
          ruangan: scheduleData.first['ruangan'] as String,
          dosen: scheduleData.first['dosen'] as String,
          hari: scheduleData.first['hari'] as String,
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