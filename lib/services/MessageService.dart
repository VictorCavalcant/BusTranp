import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class MessageService {
  final _firebaseMessaging = FirebaseMessaging.instance;

  String? fCMToken = "";

  Future<void> initNotification() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      sound: true,
    );

    print('Permission status: ${settings.authorizationStatus} ');

    fCMToken = await _firebaseMessaging.getToken();

    print("fcmToken ---> $fCMToken");
  }

  Future<void> sendNotification(
      {required String title,
      required String body,
      required String distance}) async {
    // Substitua pelo seu ID do projeto do Firebase
    const String projectId = "ubus-61adb";

    // Endpoint da API HTTP v1
    final String endpoint =
        "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

    // Substitua pelo caminho para o arquivo de chave de conta de serviço
    final serviceAccountKey = {
      "client_email":
          "firebase-adminsdk-yy6hz@ubus-61adb.iam.gserviceaccount.com",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDoBh80Gft4J86Y\n1osSj5EQX2qewy06MWXo/H53qOeeORj7oL38ltF/in7IAWAf6O7tDIxct7szXsng\nvCELbrTRKz2vT5Akh4IwFOXQWiKKXZDcGrLjLmCaqB6wHYGbP1v4lg1Snfq5mMDk\nEjlSDanvsv6T7JiOugD+bDFzeoT9Lu4TC3wq+PdQiSyA+Z+azgBNUrdCxYh2HWDR\nC8izwzYrpxefmrhVh6Xxa3jRC1yNXGZb0zkBhvGsSEEOeSPLhqCjh+fEbdaU0wt6\nGG/WbCKdRk/dXXWZwehwSkLjZV2DKdIJU1k/vln12kY9YE/EPa3UYPpPM2Jy2/Po\nOChsMzBJAgMBAAECgf8gQA7rmbDvwpi00HKu4cWywOXRANAIhqqOTTTxl53vdYBD\neX7u3QfBnT6CDlmOFefKizP3WefAptbopehHQ9wI4Y8cDwhkthvNExqJG1OHEqT6\nnbtqWHKVDJ6MsY088absUUReIhdM34PwL5hID3N6HdHE6IihTg6qo987wzaOT56D\nGTVZRTOzFYR+anSN4GlWNiwMa9Em1Gl2cY3T7dT+UjEk0xikzCwdfsCTTtvRaOIa\nLZcjxGjOvmIYDgDP0ZUHWgCtUsEFIFkeR5CVBLcN6+yoLdnBtHHn1PM9BcJvRnaL\nYyW4sLOlVxrLc+cGLBTsYkGhNhETg7sXkns6HkECgYEA+SZhZO4x7jJydWIPrOz4\nKzncqumNvTpMzDFMws9XdT3QewD9VES3WrcgQJuXZmsXuc4RvxyN8+QVswDDnc2r\nwf1ypxm9Dz/vijbpYDaf1fgCD5qVFMXfhxNKzgHbSKMyY5r05u0AOyDTBvTscuwR\nbtPQ1FAQIceHm0aIZqU9S6kCgYEA7mczmIRGXxE9UnBUbmXm3bukv4kb+98H4Q8Z\nbqf9fSPk3Z8YXbLaArZkJ4OO0KfU6Z6zgABgW17HELhsSABV7+8abDoINPlr8pzL\na7+TAS4tBYqUw5zthSPZhlyj4GybPV4PIJqn5A7heRDh9P4BhHW4ORWNwUyeRxPQ\nzWnqo6ECgYEA0fRo4H/lbZ/vWkG/ie7LlsmUziYwfkSx0OS+le/Z+H+VvwHveOLL\nTFPDhw5WwEUA4l/oDo+Gg/8x1f2P2twloDzvMCd9bWtodaWedqixesMbIYEXnkC9\nA/va7s0buBNmdA9xz2Pq7OjVTCh7VMDgU++FLFUnsv+Mo+oFKdKXW7kCgYEAtFeN\nSEqHkVLROJOQyxJ62jEgJ2Por1e/9hgd/P9HWmrUrnGzVO3+zR58FQgH+P98qF1N\nG/8s5PGFVLit8KmQWLhfHI+ptakYZ6cEmrWI1tO/avmyH2eOpbDA1EswDI0bwght\nGRTk/DfliFelFlcvfqwud8A+Q4NaGBp9UWZWAQECgYAubtAUKRYfp2j+qHT3dkTX\nKKIoFD/LXWK6/qIMgW/k7rCKCU+xTyePg7aWgzGcBu+cIxDo5VoiqpNIaFO5bIF1\nytqFdnXm8APddTfXVNG1bkhyghriJ3RzqK4gD0eLwELk1ojlWGscK1KvvMe41HmG\nTRwYO/TRcSK9P4jTSseG2A==\n-----END PRIVATE KEY-----\n",
      "project_id": projectId,
    };

    // Obter o token de acesso OAuth 2.0
    final String accessToken = await _getAccessToken(serviceAccountKey);

    // Cabeçalhos da requisição
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    // Corpo da mensagem
    final bodyData = {
      "message": {
        "token": await _firebaseMessaging.getToken(),
        "notification": {
          "title": title,
          "body": body,
        },
        "data": {
          "distance": distance,
          "key2": "value2",
        },
      },
    };

    // Enviar a requisição
    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 200) {
      print("Notificação enviada com sucesso!");
    } else {
      print("Erro ao enviar notificação: ${response.body}");
    }
  }

  // Função para obter o token de acesso OAuth 2.0
  Future<String> _getAccessToken(Map<String, dynamic> serviceAccountKey) async {
    final jwt = _generateJWT(serviceAccountKey);
    final response = await http.post(
      Uri.parse("https://oauth2.googleapis.com/token"),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': jwt,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Aqui você pode exibir a notificação manualmente usando o plugin flutter_local_notifications
        print(
            'Mensagem recebida: ${message.notification?.title}, ${message.notification?.body}');
      });
      return data['access_token'];
    } else {
      throw Exception("Erro ao obter token de acesso: ${response.body}");
    }
  }

  // Função para gerar o JWT (JSON Web Token)
  String _generateJWT(Map<String, dynamic> serviceAccountKey) {
    final clientEmail = serviceAccountKey['client_email'];
    final privateKey = serviceAccountKey['private_key'];
    final projectId = serviceAccountKey['project_id'];

    if (clientEmail == null || privateKey == null || projectId == null) {
      throw Exception("Chave da conta de serviço inválida.");
    }

    // Define as informações do JWT
    final jwt = JWT(
      {
        "iss": clientEmail, // Emissor
        "scope": "https://www.googleapis.com/auth/firebase.messaging", // Escopo
        "aud": "https://oauth2.googleapis.com/token", // Destinatário
        "exp": DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000, // Expiração (1 hora)
        "iat": DateTime.now().millisecondsSinceEpoch ~/ 1000, // Emitido em
      },
    );

    // Assina o JWT com a chave privada
    return jwt.sign(
      RSAPrivateKey(privateKey),
      algorithm: JWTAlgorithm.RS256,
    );
  }
}
