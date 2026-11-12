import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/chat_message.dart';

class ApiService {
  // Production Cloud Base URL (Render FastAPI Backend)
  static String get defaultBaseUrl {
    return "https://vedaguru-api.onrender.com/api";
  }

  static String baseUrl = defaultBaseUrl;

  // ==================== 1. Authentication APIs ====================
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/login');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'user': UserModel.fromJson(data)};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Login failed. Please verify credentials.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Cannot connect to VedaGuru server at $baseUrl: $e'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String defaultRegion = 'General/Standard',
    String preferredLanguage = 'English',
    String accountType = 'User',
    String securityQuestion = '',
    String securityAnswer = '',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/register');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'default_region': defaultRegion,
          'preferred_language': preferredLanguage,
          'account_type': accountType,
          'security_question': securityQuestion,
          'security_answer': securityAnswer,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Cannot connect to VedaGuru server at $baseUrl: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String newRegion,
    required String newLanguage,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/profile');
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'new_region': newRegion,
          'new_language': newLanguage,
        }),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'message': data['message'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== 2. Panchang & Astrology Clock APIs ====================
  static Future<Map<String, dynamic>> getLivePanchang({
    required String location,
    String language = 'English',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/panchang/live');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'location': location, 'language': language}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'panchang': data['panchang']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to fetch Panchang'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUpcomingFestivals({
    required String location,
    String language = 'English',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/panchang/festivals');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'location': location, 'language': language}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'festivals': data['festivals'] ?? []};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to fetch festivals'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<String> getDailyWisdom({String language = 'English'}) async {
    try {
      final uri = Uri.parse('$baseUrl/panchang/daily-wisdom?language=$language');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['wisdom'] ?? '';
      }
    } catch (_) {}
    return 'Dharmo Rakshati Rakshitah - Dharma protects those who uphold Dharma.';
  }

  static Future<Map<String, dynamic>> getMuhurat({
    required String eventType,
    required String targetDate,
    String location = 'India',
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/panchang/muhurat');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'event_type': eventType,
          'target_date': targetDate,
          'location': location,
          'language': language,
          'username': username,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'muhurat_details': data['muhurat_details']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to calculate Muhurat'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== 3. Rituals & Pooja Engine APIs ====================
  static Future<Map<String, dynamic>> getMasterPlan({
    required String devoteeName,
    required String location,
    required String poojaName,
    required String startDate,
    required String endDate,
    String region = 'General/Standard',
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/pooja/master-plan');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'devotee_name': devoteeName,
          'location': location,
          'pooja_name': poojaName,
          'start_date': startDate,
          'end_date': endDate,
          'region': region,
          'language': language,
          'username': username,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'master_plan': data['master_plan']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to generate Master Plan'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSamagriList({
    required String poojaName,
    String region = 'General/Standard',
    int peopleCount = 5,
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/pooja/samagri');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pooja_name': poojaName,
          'region': region,
          'people_count': peopleCount,
          'language': language,
          'username': username,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'samagri_list': data['samagri_list']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to generate Samagri'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPoojaGuidance({
    required String poojaName,
    String region = 'General/Standard',
    String stepDetail = 'Complete Detailed Vidhi',
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/pooja/guidance');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pooja_name': poojaName,
          'region': region,
          'step_detail': stepDetail,
          'language': language,
          'username': username,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'vidhi': data['vidhi']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to generate Vidhi guidance'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== 4. AI Chat & Memory APIs ====================
  static Future<Map<String, dynamic>> askVedicChat({
    required String username,
    required String message,
    String language = 'English',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/ask');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'message': message,
          'language': language,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'reply': data['reply']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Chat request failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<List<ChatMessage>> getChatHistory(String username) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/history/$username');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['history'] as List? ?? []);
        return list.map((item) => ChatMessage.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> clearChatHistory(String username) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/history/$username');
      final res = await http.delete(uri);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==================== 5. Sacred Wisdom & Chanting APIs ====================
  static Future<Map<String, dynamic>> exploreScripture({
    required String category,
    required String bookName,
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/wisdom/library/explore');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'category': category,
          'book_name': bookName,
          'language': language,
          'username': username,
        }),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'content': data['content'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> askScripture({
    required String bookName,
    required String question,
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/wisdom/library/ask');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'book_name': bookName,
          'question': question,
          'language': language,
          'username': username,
        }),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'answer': data['answer'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAarti({
    required String deityName,
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/wisdom/aarti');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deity_name': deityName, 'language': language, 'username': username}),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'content': data['content'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMantra({
    required String mantraName,
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/wisdom/mantra');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mantra_name': mantraName, 'language': language, 'username': username}),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'content': data['content'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getKatha({
    required String topic,
    String source = 'Any',
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/wisdom/katha');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'topic': topic, 'source': source, 'language': language, 'username': username}),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'katha': data['katha'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== 6. Astrology & Jyotish APIs ====================
  static Future<Map<String, dynamic>> getKundali({
    required String nativeName,
    required String birthDate,
    required String birthTime,
    required String birthCity,
    String analysisType = 'Detailed Life Horoscope',
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/astrology/kundali');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'native_name': nativeName,
          'birth_date': birthDate,
          'birth_time': birthTime,
          'birth_city': birthCity,
          'analysis_type': analysisType,
          'language': language,
          'username': username,
        }),
      );
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200,
        'reading': data['reading'] ?? data['detail'],
        'resolved_location': data['resolved_location'],
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMatchmaking({
    required String boyName,
    required String boyDob,
    required String boyTob,
    required String boyCity,
    required String girlName,
    required String girlDob,
    required String girlTob,
    required String girlCity,
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/astrology/matchmaking');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'boy_name': boyName,
          'boy_dob': boyDob,
          'boy_tob': boyTob,
          'boy_city': boyCity,
          'girl_name': girlName,
          'girl_dob': girlDob,
          'girl_tob': girlTob,
          'girl_city': girlCity,
          'language': language,
          'username': username,
        }),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'report': data['report'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getRashichakra({
    required String rashiName,
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/astrology/rashichakra');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rashi_name': rashiName, 'language': language, 'username': username}),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'profile': data['profile'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== 7. Sacred Lifestyle & Wellness APIs ====================
  static Future<Map<String, dynamic>> getVratMeal({
    required String vratType,
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/lifestyle/annapurna/vrat');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'vrat_type': vratType, 'language': language, 'username': username}),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'meal_plan': data['meal_plan'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPrasadRecipe({
    required String deityName,
    String region = 'General/Standard',
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/lifestyle/annapurna/prasad');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deity_name': deityName, 'region': region, 'language': language, 'username': username}),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'recipe': data['recipe'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> logChantingSession({
    required String username,
    required String chantName,
    int count = 108,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/lifestyle/chanting/log');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'chant_name': chantName, 'count': count}),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'message': data['message'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getVastuAnalysis({
    required String mainDoor,
    required String kitchen,
    required String bedroom,
    String poojaRoom = 'East',
    String otherDetails = '',
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/lifestyle/vastu');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'main_door': mainDoor,
          'kitchen': kitchen,
          'bedroom': bedroom,
          'pooja_room': poojaRoom,
          'other_details': otherDetails,
          'language': language,
          'username': username,
        }),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'analysis': data['analysis'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getTirthItinerary({
    required String startCity,
    required String destination,
    int days = 3,
    int peopleCount = 2,
    String language = 'English',
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/lifestyle/tirth');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'start_city': startCity,
          'destination': destination,
          'days': days,
          'people_count': peopleCount,
          'language': language,
          'username': username,
        }),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'itinerary': data['itinerary'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== 8. Workspace, CRM & Community APIs ====================
  static Future<List<dynamic>> getUserHistory(String username) async {
    try {
      final uri = Uri.parse('$baseUrl/workspace/history/$username');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['history'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getCommunityFeed() async {
    try {
      final uri = Uri.parse('$baseUrl/workspace/community');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['posts'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> addCommunityVidhi({
    required String username,
    required String title,
    required String region,
    required String content,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/workspace/community');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'title': title, 'region': region, 'content': content}),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'message': data['message'] ?? data['detail']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<bool> deleteCommunityVidhi(int vidhiId) async {
    try {
      final uri = Uri.parse('$baseUrl/workspace/community/$vidhiId');
      final res = await http.delete(uri);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getYagyaBoards(String username) async {
    try {
      final uri = Uri.parse('$baseUrl/workspace/yagya/boards/$username');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['boards'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getUserBookings(String username) async {
    try {
      final uri = Uri.parse('$baseUrl/yajman/bookings/$username');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['bookings'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getPurohitClients(String purohitUsername) async {
    try {
      final uri = Uri.parse('$baseUrl/yajman/list/$purohitUsername');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['clients'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  // ==================== Password Recovery & Change ====================
  static Future<Map<String, dynamic>> getRecoveryInfo(String username) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/recovery-info/$username');
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {
          'success': true,
          'has_security_question': data['has_security_question'] ?? false,
          'security_question': data['security_question'] ?? '',
        };
      } else {
        return {'success': false, 'error': data['detail'] ?? 'User not found'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String username,
    required String newPassword,
    String securityAnswer = '',
    String? verifyRegion,
    String? verifyRole,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/reset-password');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'new_password': newPassword,
          'security_answer': securityAnswer,
          'verify_region': verifyRegion,
          'verify_role': verifyRole,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Password reset successfully'};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Reset password failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/change-password');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Password updated successfully'};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to change password'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // ==================== Purohit Directory & Reviews ====================
  static Future<List<dynamic>> getPurohitsDirectory() async {
    try {
      final uri = Uri.parse('$baseUrl/yajman/purohits-directory');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['purohits'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getPurohitReviews(String purohitUsername) async {
    try {
      final uri = Uri.parse('$baseUrl/workspace/reviews/$purohitUsername');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['reviews'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> deleteClient(int clientId) async {
    try {
      final uri = Uri.parse('$baseUrl/yajman/delete/$clientId');
      final res = await http.delete(uri);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getPendingBookings({String? purohitUsername}) async {
    try {
      final query = (purohitUsername != null && purohitUsername.isNotEmpty)
          ? '?purohit_username=$purohitUsername'
          : '';
      final uri = Uri.parse('$baseUrl/yajman/pending-bookings$query');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['bookings'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getPurohitBookings(String purohitUsername, {String? status}) async {
    try {
      final query = (status != null && status.isNotEmpty) ? '?status=$status' : '';
      final uri = Uri.parse('$baseUrl/yajman/purohit-bookings/$purohitUsername$query');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['bookings'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> acceptBooking(int bookingId, String purohitUsername) async {
    try {
      final uri = Uri.parse('$baseUrl/yajman/bookings/$bookingId/accept?purohit_username=$purohitUsername');
      final res = await http.put(uri);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> completeBooking(int bookingId, {int rating = 5, String feedback = ''}) async {
    try {
      final uri = Uri.parse('$baseUrl/yajman/bookings/$bookingId/complete');
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rating': rating,
          'feedback': feedback,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse('$baseUrl/yajman/reverse-geocode?lat=$lat&lng=$lng');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  // ==================== Admin Dashboard APIs ====================
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final uri = Uri.parse('$baseUrl/workspace/admin/stats');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      } else {
        final data = jsonDecode(res.body);
        return {'success': false, 'error': data['detail'] ?? 'Failed to load stats'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<List<dynamic>> getAdminUsers() async {
    try {
      final uri = Uri.parse('$baseUrl/workspace/admin/users');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['users'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  // ==================== Universal PDF Report Export ====================
  static Future<List<int>?> downloadPdfReport({
    required String title,
    required String content,
    String? subtitle,
    String language = 'English',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/pooja/pdf-report');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'content': content,
          'subtitle': subtitle ?? '',
          'language': language,
        }),
      );
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }
}
