import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

import 'method_channel_firestore.dart';

import 'utils/exception.dart';

class MethodChannelLoadBundleTask extends LoadBundleTaskPlatform {
  MethodChannelLoadBundleTask(Future<String?> task, Uint8List bundle,
      MethodChannelFirebaseFirestore firestore)
      : super() {
    Stream<LoadBundleTaskSnapshotPlatform> mapNativeStream() async* {
      final observerId = await task;

      final nativePlatformStream =
          MethodChannelFirebaseFirestore.loadBundleChannel(observerId!)
              .receiveBroadcastStream(
        <String, Object>{'bundle': bundle, 'firestore': firestore},
      );
      try {
        await for (final snapshot in nativePlatformStream) {
          final taskState = convertToTaskState(snapshot['taskState']);

          yield LoadBundleTaskSnapshotPlatform(
              taskState, Map<String, dynamic>.from(snapshot));

          if (taskState == LoadBundleTaskState.success) {
            // this will close the stream and stop listening to nativePlatformStream
            return;
          }
        }
      } catch (e) {
        throw convertPlatformException(e);
      }
    }

    stream =
        mapNativeStream().asBroadcastStream(onCancel: (sub) => sub.cancel());
  }

  @override
  // ignore: overridden_fields
  late Stream stream;
}
