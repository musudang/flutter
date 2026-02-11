import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meetup_model.dart';
import '../models/user_model.dart' as app_models;
import '../models/post_model.dart';
import '../models/question_model.dart';
import '../models/message_model.dart';

import 'dart:async';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get Current App User (Fetches from Firestore 'users' collection using Auth UID)
  // Get Current App User (Fetches from Firestore 'users' collection using Auth UID)
  // Get Current App User (Fetches from Firestore 'users' collection using Auth UID)
  // Get Current App User (Fetches from Firestore 'users' collection using Auth UID)
  Future<app_models.User?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return app_models.User(
            id: data['id'] ?? user.uid,
            name: data['name'] ?? user.displayName ?? 'User',
            avatarUrl: data['avatarUrl'] ?? user.photoURL ?? '',
            nationality: data['nationality'] ?? 'Global 🌍',
          );
        }
      } else {
        // Doc doesn't exist, auto-create it
        debugPrint("User doc missing. Auto-creating for ${user.uid}");
        final newUser = app_models.User(
          id: user.uid,
          name: user.displayName ?? 'User',
          avatarUrl: user.photoURL ?? '',
          nationality: 'Global 🌍',
        );

        await _db.collection('users').doc(user.uid).set({
          'id': newUser.id,
          'name': newUser.name,
          'email': user.email,
          'avatarUrl': newUser.avatarUrl,
          'nationality': newUser.nationality,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return newUser;
      }
    } catch (e) {
      debugPrint("Error fetching/creating user from Firestore: $e");
    }

    // Fallback if Firestore doc is missing or error occurs
    return app_models.User(
      id: user.uid,
      name: user.displayName ?? 'User',
      avatarUrl: user.photoURL ?? '',
      nationality: 'Global 🌍',
    );
  }

  // Helper getter for Auth UID
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of Meetups
  Stream<List<Meetup>> getMeetups() {
    return _db.collection('meetups').orderBy('dateTime').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => _fromDocument(doc)).toList();
    });
  }

  // Stream of Single Meetup
  Stream<Meetup> getMeetup(String id) {
    return _db.collection('meetups').doc(id).snapshots().map((doc) {
      if (!doc.exists) throw Exception("Meetup not found");
      return _fromDocument(doc);
    });
  }

  // Add Meetup
  Future<void> addMeetup(Meetup meetup) async {
    if (_auth.currentUser == null) {
      debugPrint('Error: User must be logged in to write to Firestore');
      throw Exception('User must be logged in to create a meetup');
    }

    debugPrint("Attempting to save meetup... Title: ${meetup.title}");
    try {
      await _db.collection('meetups').doc(meetup.id).set(_toDocument(meetup));
      debugPrint("Meetup saved successfully!");
    } catch (e) {
      debugPrint("Error saving meetup: $e");
      rethrow;
    }
  }

  // Join Meetup
  Future<bool> joinMeetup(String meetupId) async {
    final uid = currentUserId;
    if (uid == null) {
      debugPrint("Error: User not logged in trying to join meetup.");
      return false;
    }

    final docRef = _db.collection('meetups').doc(meetupId);

    try {
      return await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          debugPrint("Error: Meetup $meetupId does not exist!");
          throw Exception("Meetup does not exist!");
        }

        final meetup = _fromDocument(snapshot);

        if (meetup.participantIds.contains(uid)) {
          debugPrint("User already joined.");
          return false; // Already joined
        }

        // Robust Full Check
        if (meetup.participantIds.length >= meetup.maxParticipants) {
          debugPrint(
            "Meetup is full! (${meetup.participantIds.length}/${meetup.maxParticipants})",
          );
          return false; // Full
        }

        final updatedParticipants = List<String>.from(meetup.participantIds)
          ..add(uid);

        transaction.update(docRef, {'participantIds': updatedParticipants});
        debugPrint("Successfully joined meetup!");
        return true;
      });
    } catch (e) {
      debugPrint("Error joining meetup: $e");
      return false;
    }
  }

  // Leave Meetup
  Future<void> leaveMeetup(String meetupId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final docRef = _db.collection('meetups').doc(meetupId);

    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("Meetup does not exist!");

        final meetup = _fromDocument(snapshot);
        if (!meetup.participantIds.contains(uid)) {
          return; // Not joined
        }

        final updatedParticipants = List<String>.from(meetup.participantIds)
          ..remove(uid);
        transaction.update(docRef, {'participantIds': updatedParticipants});
      });
    } catch (e) {
      debugPrint("Error leaving meetup: $e");
    }
  }

  // Helper: Convert DocumentSnapshot to Meetup
  Meetup _fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Meetup(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      category: MeetupCategory.values.firstWhere(
        (e) => e.toString() == 'MeetupCategory.${data['category']}',
        orElse: () => MeetupCategory.other,
      ),
      maxParticipants: data['maxParticipants'] ?? 0,
      host: app_models.User(
        id: data['hostId'] ?? '',
        name: data['hostName'] ?? 'Unknown',
        avatarUrl: data['hostAvatar'] ?? '',
      ),
      participantIds: List<String>.from(data['participantIds'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  // Helper: Convert Meetup to Map
  Map<String, dynamic> _toDocument(Meetup meetup) {
    return {
      'title': meetup.title,
      'description': meetup.description,
      'location': meetup.location,
      'dateTime': Timestamp.fromDate(meetup.dateTime),
      'category': meetup.category.name, // Storing as string name
      'maxParticipants': meetup.maxParticipants,
      'hostId': meetup.host.id,
      'hostName': meetup.host.name,
      'hostAvatar': meetup.host.avatarUrl,
      'participantIds': meetup.participantIds,
      'imageUrl': meetup.imageUrl,
    };
  }

  // --- Posts (Feed) ---

  // --- Posts (Feed) ---

  // --- Posts (Feed) ---

  // Unified Feed (Posts + Meetups)
  Stream<List<dynamic>> getFeed() {
    final controller = StreamController<List<dynamic>>();
    final postsStream = getPosts();
    final meetupsStream = getMeetups();

    List<Post>? posts;
    List<Meetup>? meetups;

    StreamSubscription? postsSub;
    StreamSubscription? meetupsSub;

    void emit() {
      // If either list is available, we can emit (treating null as empty if one loaded and other failed/waiting,
      // but simpler to wait for both initially or just handle nulls)
      // Let's output whatever we have, defaulting to empty list if null
      final currentPosts = posts ?? [];
      final currentMeetups = meetups ?? [];

      final allItems = <dynamic>[...currentPosts, ...currentMeetups];
      allItems.sort((a, b) {
        final DateTime timeA = a is Post ? a.timestamp : (a as Meetup).dateTime;
        final DateTime timeB = b is Post ? b.timestamp : (b as Meetup).dateTime;
        return timeB.compareTo(timeA); // Descending
      });
      controller.add(allItems);
    }

    postsSub = postsStream.listen((data) {
      posts = data;
      emit();
    }, onError: controller.addError);

    meetupsSub = meetupsStream.listen((data) {
      meetups = data;
      emit();
    }, onError: controller.addError);

    controller.onCancel = () {
      postsSub?.cancel();
      meetupsSub?.cancel();
    };

    return controller.stream;
  }

  Stream<List<Post>> getPosts() {
    return _db
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Post(
              id: doc.id,
              authorId: data['authorId'] ?? '',
              authorName: data['authorName'] ?? 'Unknown',
              content: data['content'] ?? '',
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              likes: data['likes'] ?? 0,
              comments: data['comments'] ?? 0,
            );
          }).toList();
        });
  }

  Future<void> addPost(
    String content,
    String authorId,
    String authorName,
  ) async {
    if (_auth.currentUser == null) {
      debugPrint('Error: User must be logged in to write to Firestore');
      throw Exception('User must be logged in to post');
    }

    debugPrint(
      "Attempting to save post... Content: $content, Author: $authorName",
    );
    try {
      await _db.collection('posts').add({
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
      });
      debugPrint("Post saved successfully!");
    } catch (e) {
      debugPrint("Error saving post: $e");
      rethrow;
    }
  }

  // --- Questions (QnA) ---

  Stream<List<Question>> getQuestions() {
    return _db
        .collection('questions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Question(
              id: doc.id,
              title: data['title'] ?? '',
              content: data['content'] ?? '',
              authorId: data['authorId'] ?? '',
              authorName: data['authorName'] ?? 'Unknown',
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              answersCount: data['answersCount'] ?? 0,
            );
          }).toList();
        });
  }

  Future<void> addQuestion(
    String title,
    String content,
    String authorId,
    String authorName,
  ) async {
    if (_auth.currentUser == null) {
      debugPrint('Error: User must be logged in to write to Firestore');
      throw Exception('User must be logged in to ask a question');
    }
    await _db.collection('questions').add({
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'timestamp': FieldValue.serverTimestamp(),
      'answersCount': 0,
    });
  }

  // --- Meetup Chat ---

  Stream<List<Message>> getMeetupMessages(String meetupId) {
    return _db
        .collection('meetups')
        .doc(meetupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Message(
              id: doc.id,
              senderId: data['senderId'] ?? '',
              senderName: data['senderName'] ?? 'Unknown',
              senderAvatar: data['senderAvatar'] ?? '',
              content: data['content'] ?? '',
              timestamp: (data['timestamp'] as Timestamp).toDate(),
            );
          }).toList();
        });
  }

  Future<void> sendMeetupMessage(String meetupId, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userData = await getCurrentUser();

    await _db.collection('meetups').doc(meetupId).collection('messages').add({
      'senderId': user.uid,
      'senderName': userData?.name ?? 'Unknown',
      'senderAvatar': userData?.avatarUrl ?? '',
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
