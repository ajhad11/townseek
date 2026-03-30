import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/login_log_service.dart';

class UserManager extends ChangeNotifier {
  static final UserManager instance = UserManager._internal();

  factory UserManager() {
    return instance;
  }

  UserManager._internal();

  String _name = 'User';
  String? _profileImage;
  String _phone = '';
  dynamic _localImageFile; // Change to dynamic for web support

  String get name => _name;
  String get profileImage => _profileImage ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_name)}&background=random&size=150';
  String get phone => _phone;
  dynamic get localImageFile => _localImageFile;

  Future<void> fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle(); 
        
        if (response != null) {
          _name = response['name'] ?? 'User';
          _phone = response['phone'] ?? '';
          _profileImage = response['avatar_url'];
          
          // Log the login activity with role
          LoginLogService.logLogin(user, role: response['role']);
        } else {
          final metadata = user.userMetadata;
          if (metadata != null) {
            final name = metadata['name'] ?? 'User';
            final phone = metadata['phone'] ?? '';
            
            await Supabase.instance.client.from('profiles').insert({
              'id': user.id,
              'name': name,
              'phone': phone,
            });
            
            _name = name;
            _phone = phone;

            // Log the login activity for newly created profile
            LoginLogService.logLogin(user, role: 'user');
          }
        }
        
        notifyListeners();
      } catch (e) {
        debugPrint('Error fetching/creating profile: $e');
      }
    }
  }

  Future<void> updateProfile({
    String? name,
    String? image,
    dynamic localImage,
    bool clearLocalImage = false,
    String? phone,
  }) async {
    if (name != null) _name = name;
    if (image != null) _profileImage = image == '' ? null : image;
    
    if (clearLocalImage) {
      _localImageFile = null;
    } else if (localImage != null) {
      _localImageFile = localImage;
    } 
    
    if (phone != null) _phone = phone;
    
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final upsertData = <String, dynamic>{'id': user.id};
        if (name != null) upsertData['name'] = name;
        if (phone != null) upsertData['phone'] = phone;

        if (image == '') {
          upsertData['avatar_url'] = null;
        } else if (image != null && localImage == null) {
          upsertData['avatar_url'] = image;
        }

        // Use upsert so the row is created if it doesn't exist yet,
        // preventing silent data loss when UPDATE finds no matching row.
        await Supabase.instance.client
            .from('profiles')
            .upsert(upsertData);
      }
    } catch (e) {
      debugPrint('Error updating profile in DB: $e');
    }
  }

  void setLocalImage(dynamic file) {
    _localImageFile = file;
    notifyListeners();
  }

  void clearProfile() {
      _name = 'User';
      _phone = '';
      _localImageFile = null;
      notifyListeners();
  }

  Future<String?> uploadProfileImage(dynamic file) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final storage = Supabase.instance.client.storage.from('profile-images');
      
      // Get old image path from database
      String? oldImagePath;
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .maybeSingle();
            
        final avatarUrl = profile?['avatar_url'] as String?;
        if (avatarUrl != null) {
          final bucketIndex = avatarUrl.indexOf('profile-images/');
          if (bucketIndex != -1) {
            oldImagePath = avatarUrl.substring(bucketIndex + 'profile-images/'.length);
          }
        }
      } catch (e) {
        debugPrint('Error fetching old profile image path: $e');
      }

      // Delete old image from bucket
      if (oldImagePath != null) {
        try {
          await storage.remove([oldImagePath]);
        } catch (e) {
          debugPrint('Error removing old image from storage: $e');
        }
      }

      String fileName;
      if (kIsWeb) {
        fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await storage.uploadBinary(fileName, file);
      } else {
        String fileExt = 'jpg';
        try {
          if (file is io.File) {
            fileExt = file.path.split('.').last;
          }
        } catch (e) {
          debugPrint('Error getting file extension, defaulting to jpg: $e');
        }
        fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await storage.upload(fileName, file as io.File);
      }

      final imageUrl = storage.getPublicUrl(fileName);

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', user.id);

      _profileImage = imageUrl;
      _localImageFile = null;
      notifyListeners();
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  Future<void> deleteProfileImage() async {
     try {
       final user = Supabase.instance.client.auth.currentUser;
       if (user == null) return;
       
       final storage = Supabase.instance.client.storage.from('profile-images');
       
       try {
         final List<FileObject> objects = await storage.list(path: user.id);
         if (objects.isNotEmpty) {
            final List<String> pathsToDelete = objects.map((obj) => '${user.id}/${obj.name}').toList();
            await storage.remove(pathsToDelete);
         }
       } catch (e) {
         debugPrint('Error clearing images from storage: $e');
       }

       await Supabase.instance.client
           .from('profiles')
           .upsert({'id': user.id, 'avatar_url': null});

       _profileImage = null;
       _localImageFile = null;
       notifyListeners();
     } catch(e) {
       debugPrint('Error deleting profile image: $e');
       rethrow;
     }
  }
}
