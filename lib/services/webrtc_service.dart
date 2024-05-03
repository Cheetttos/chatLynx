import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStreamTrack? _videoTrack;

  Future<void> initialize() async {
    // Crear una nueva conexión de pares
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    });

    // Crear un nuevo flujo de medios local
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    // Obtener el track de video del flujo de medios local
    _videoTrack = _localStream!.getVideoTracks().first;

    // Agregar el track de video al peer connection
    await _peerConnection!.addTrack(_videoTrack!, _localStream!);
  }

  Future<void> startCall() async {
    // Crear una oferta de señalización
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Aquí iría la lógica para enviar la oferta al otro usuario
    // Por ejemplo, podrías enviar la oferta a un servidor backend
    // y luego recibir la respuesta de vuelta para continuar con la señalización
  }

  Future<void> handleRemoteStream(MediaStream stream) async {
    // Agregar el flujo de video remoto a la conexión de pares
    await _peerConnection!.addStream(stream);
  }
}
