import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final List<String> participantIds;
  final List<String> participantNames;
  final List<String> participantProfilePictures;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.participantIds,
    required this.participantNames,
    required this.participantProfilePictures,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late final AgoraClient _client;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    _client = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: '16f31e0ef4b740da89b0e2365b20306a',
        channelName: widget.channelName,
        tempToken:
            '007eJxTYDCpsam7fPbJs6/3j9tZabzNmB2/buHStbbsAd4ymmye1y0UGAzN0owNUw1S00ySzE0MUhItLJMMUo2MzUyTjAyMDcwSnXaYpDUEMjLMdFvNxMgAgSA+J0NZZkpqfnJiTg4DAwD0mSDD',
      ),
    );
    await _client.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Videollamada'),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              AgoraVideoViewer(
                client: _client,
                layoutType: Layout.floating,
                showNumberOfUsers: true,
              ),
              AgoraVideoButtons(
                client: _client,
                enabledButtons: const [
                  BuiltInButtons.toggleCamera,
                  BuiltInButtons.callEnd,
                  BuiltInButtons.toggleMic,
                  BuiltInButtons.switchCamera
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}