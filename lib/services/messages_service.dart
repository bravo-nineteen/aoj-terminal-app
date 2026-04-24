import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aoj_models.dart';

class MessagesService {
  static SupabaseClient get _db => Supabase.instance.client;

  static bool _isHostLookupError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('failed host lookup') ||
        message.contains('name or service not known') ||
        message.contains('temporary failure in name resolution');
  }

  static Future<T> _withHostLookupRetry<T>(Future<T> Function() action) async {
    Object? lastError;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        final isRetryable = _isHostLookupError(e);
        final isLast = attempt == 2;
        if (!isRetryable || isLast) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 700 * (attempt + 1)));
      }
    }
    throw lastError ?? StateError('Unknown host lookup failure');
  }

  static Future<List<MessageRecord>> fetchMessages({String? eventId}) async {
    try {
      return await _withHostLookupRetry(() async {
        final query = _db.from('messages').select().order('created_at');
        final List<Map<String, dynamic>> rows =
            List<Map<String, dynamic>>.from(await query);
        return rows
            .where((r) => eventId == null || (r['event_id'] as String?) == eventId)
            .map(
              (r) => MessageRecord(
                id: r['id'] as String? ?? '',
                sender: r['sender'] as String? ?? '',
                body: r['body'] as String? ?? '',
                createdAt: (r['created_at'] as String?) ?? '',
                eventId: r['event_id'] as String?,
              ),
            )
            .toList();
      });
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        throw StateError(
          'Supabase table public.messages is missing. Apply migrations (supabase db push) to create it.',
        );
      }
      if (e.code == '42501') {
        throw StateError(
          'Missing RLS permissions for public.messages. Apply RLS policy migration.',
        );
      }
      rethrow;
    }
  }

  static Future<void> sendMessage({
    required String sender,
    required String body,
    String? eventId,
  }) async {
    try {
      await _withHostLookupRetry(() async {
        await _db.from('messages').insert(<String, dynamic>{
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'sender': sender,
          'body': body,
          'event_id': eventId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      });
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        throw StateError(
          'Supabase table public.messages is missing. Apply migrations (supabase db push) to create it.',
        );
      }
      if (e.code == '42501') {
        throw StateError(
          'Missing RLS permissions for public.messages. Apply RLS policy migration.',
        );
      }
      rethrow;
    }
  }
}
