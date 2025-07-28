// lib/src/mock/mock_events.dart

/// Mock data basado en tu JSON real de 5 eventos
/// Para testing de arquitectura cache + scroll 90Hz
class MockEvents {
  static const List<Map<String, dynamic>> events = [
    {
      "id": 6,
      "title": "Hermosas Guirnaldas",
      "type": "arte",
      "code": "arte_00006",
      "location": "Atenas Estadio",
      "date": "2025-08-12T22:00",
      "price": "\$ 20.000",
      "rating": 50,
      "imageUrl": "https://misty-bread-5506.tester-passalia.workers.dev/teatro_0002.jpg",
      "description": "Pese a contar con habilitaciones municipales, personal policial asignado y servicios de emergencias disponibles, la denuncia apunta la intervención del sitio declarado patrimonio de la humanidad por la Unesco en el 2000 sin autorización a nivel nacional.",
      "address": "Alejandro Aguado 687",
      "district": "Gral Paz",
      "websiteUrl": "https://990arteclub.com",
      "lat": -31.39636078064314,
      "lng": -64.17225774519973,
      "favorite": false,
    },
    {
      "id": 7,
      "title": "Princesas Contra el Reloj",
      "type": "teatro",
      "code": "teatro_00007",
      "location": "Teatro Ciudad de las Artes",
      "date": "2025-08-12T16:00",
      "price": "Consultar",
      "rating": 100,
      "imageUrl": "https://misty-bread-5506.tester-passalia.workers.dev/teatro_00007.jpg",
      "description": "La noche del 13 de enero de 1920, la princesa Blancanieves se desmaya en un profundo sopor mágico, víctima de la maldición de la malvada bruja. Despertando de su letargo, se da cuenta de que se encuentra en una situación desesperada y que solo pueden ayudarla las valientes princesas del reino, decididas a arriesgar su seguridad para rescatar a su amiga y hermana de sangre.",
      "address": "Av. Pablo Ricchieri 1955",
      "district": "Nueva Córdoba",
      "websiteUrl": "https://www.facebook.com/teatrociudadelasartes/",
      "lat": -31.435374665746004,
      "lng": -64.17537479549907,
      "favorite": false,
    },
    {
      "id": 8,
      "title": "Fiesta Latina",
      "type": "arte",
      "code": "arte_00008",
      "location": "Atenas Estadio",
      "date": "2025-08-12T23:45",
      "price": "\$ 30.000",
      "rating": 200,
      "imageUrl": "https://misty-bread-5506.tester-passalia.workers.dev/teatro_0002.jpg",
      "description": "Pese a contar con habilitaciones municipales, personal policial asignado y servicios de emergencias disponibles, la denuncia apunta la intervención del sitio declarado patrimonio de la humanidad por la Unesco en el 2000 sin autorización a nivel nacional.",
      "address": "Alejandro Aguado 687",
      "district": "Gral Paz",
      "websiteUrl": "https://990arteclub.com",
      "lat": -31.39636078064314,
      "lng": -64.17225774519973,
      "favorite": false,
    },
    {
      "id": 9,
      "title": "Payaso Plin Plin",
      "type": "teatro",
      "code": "teatro_00009",
      "location": "Bar Oculto",
      "date": "2025-08-12T21:00",
      "price": "Consultar",
      "rating": 300,
      "imageUrl": "https://misty-bread-5506.tester-passalia.workers.dev/ninos_00003.jpg",
      "description": "✋Frente a tanta inteligencia artificial, un poco de idiotez orgánica\n\n⚘Te proponemos un espacio intensivo de entrenamiento para indagar la propia idiotez y reflexionar sobre la risa. Partiendo del fracaso como germen de la risa.\n\n🍭 El juego es nuestro espacio de verdad, dónde aparece la vulnerabilidad y la fragilidad, dónde arriesgamos y apostamos y ponemos nuestro cuerpo en pos del jugar 💖",
      "address": "Tegucigalpa 1572",
      "district": "Urca",
      "websiteUrl": "https://microteatrocordoba.com",
      "lat": -31.385042847094944,
      "lng": -64.16270631545386,
      "favorite": false,
    },
    {
      "id": 10,
      "title": "Feria Brotes",
      "type": "ferias",
      "code": "ferias_00010",
      "location": "Feria Brotes",
      "date": "2025-08-13T20:00",
      "price": "Libre y Gratuita",
      "rating": 400,
      "imageUrl": "https://misty-bread-5506.tester-passalia.workers.dev/ferias_00010.jpg",
      "description": "Los sábados de feria son verdaderamente un deleite para los sentidos. La feria ofrece una experiencia única y variada, donde la diversidad y la inclusión son Fundamentales. En este espacio, se pueden disfrutar de una gran cantidad de productos y servicios, ofrecidos por personas de todo tipo, con historias y personalidades únicas.",
      "address": "Bv. Enrique Barros",
      "district": "Nueva Córdoba",
      "websiteUrl": "https://www.instagram.com/feriabrotes",
      "lat": -31.433500888596917,
      "lng": -64.1853650279955,
      "favorite": false,
    },

  ];
  /// Simulación de metadata de Firestore
  static const Map<String, dynamic> mockMetadata = {
    "estado": "OK",
    "fecha_subida": "2025-07-25T01:49:11.071480",
    "nombre_lote": "lote_2025_07_25_mock_1",
    "total_eventos": 5  // Coincide con cantidad de eventos mock
  };

  /// Estructura completa como viene de Firestore
  static Map<String, dynamic> get mockBatch => {
    "eventos": cacheEvents,
    "metadata": mockMetadata,
  };
  /// Solo campos necesarios para cache (9 campos, 203 bytes por evento)
  static List<Map<String, dynamic>> get cacheEvents {
    return events.map((event) => {
      'id': event['id'],
      'title': event['title'],
      'type': event['type'],
      'location': event['location'],
      'date': event['date'],
      'price': event['price'],
      'district': event['district'],
      'rating': event['rating'],
      'favorite': event['favorite'],
    }).toList();
  }

  /// Evento completo por ID (para modal)
  static Map<String, dynamic>? getEventById(int id) {
    try {
      return events.firstWhere((event) => event['id'] == id);
    } catch (e) {
      return null;
    }
  }
}