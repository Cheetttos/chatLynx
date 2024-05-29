import 'package:agora_uikit/agora_uikit.dart';
import 'package:chatlynx/screens/video_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:chatlynx/incoming_call_channel.dart';

class IncomingCallScreen extends StatefulWidget {
  final String channelName;
  final String callerName;
  final String callerProfilePicture;

  const IncomingCallScreen({
    super.key,
    required this.channelName,
    required this.callerName,
    required this.callerProfilePicture,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  late final AgoraClient _client;
  late String callerName;
  late String callerProfilePicture;
  late String channelName;
  
  @override
  void initState() {
    super.initState();
    _initAgora();
    _getIncomingCallData();
  }

  Future<void> _getIncomingCallData() async {
    final data = await IncomingCallChannel.getIncomingCallData();
    setState(() {
      callerName = data['callerName'] ?? '';
      callerProfilePicture = data['callerProfilePicture'] ?? '';
      channelName = data['channelName'] ?? '';
    });
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(widget.callerProfilePicture),
            ),
            const SizedBox(height: 16),
            Text(
              'Llamada entrante de ${widget.callerName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Aceptar la llamada
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoCallScreen(
                          channelName: widget.channelName,
                          participantIds: [], // Agrega los ID de los participantes
                          participantNames: [], // Agrega los nombres de los participantes
                          participantProfilePictures: [], // Agrega las URLs de las imágenes de perfil
                        ),
                      ),
                    );
                  },
                  child: const Text('Aceptar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Rechazar la llamada
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Rechazar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
