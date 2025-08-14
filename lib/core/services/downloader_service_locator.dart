import 'downloader_service.dart';
import 'downloader_service_stub.dart'
    if (dart.library.html) 'downloader_service_web.dart';

DownloaderService getDownloaderService() => DownloaderServiceImpl();
