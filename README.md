# WhatsApp Viewer

## Descrizione

**WhatsApp Viewer** è un'applicazione desktop sviluppata con **Flutter** che permette di visualizzare e navigare le chat esportate da WhatsApp. L'applicazione consente di aprire i file di esportazione `.txt` generati da WhatsApp e di visualizzare i messaggi in un'interfaccia simile a quella di WhatsApp, con supporto per la visualizzazione di allegati multimediali come immagini, PDF e file audio.

### Funzionalità principali

- **Caricamento chat**: Apertura di file di esportazione WhatsApp (`.txt`)
- **Visualizzazione messaggi**: Interfaccia a bolle con distinzione tra messaggi inviati e ricevuti
- **Supporto media**:
  - **Immagini**: Visualizzazione di immagini (`IMG-*.jpg`, `VID-*.mp4`)
  - **PDF**: Visualizzazione PDF integrata tramite Syncfusion PDF Viewer
  - **Audio**: Riproduzione di file audio Opus (`.opus`) con controlli play/pause/stop
- **Navigazione media**: Pulsante per passare al prossimo messaggio multimediale
- **Elenco media**: Dialogo con l'elenco di tutti i messaggi multimediali ordinati per data
- **Configurazione nomi**: Possibilità di inserire i nomi del mittente e del destinatario per distinguere i messaggi
- **Ricerca per testo**: Campo di ricerca con navigazione tra i risultati (precedente/successivo) ed evidenziazione dei messaggi trovati
- **Ricerca per data**: Selettore di data con calendario limitato all'intervallo delle date dei messaggi, con individuazione del messaggio più vicino alla data selezionata

### Tecnologie utilizzate

| Tecnologia | Versione | Scopo |
|---|---|---|
| Flutter | SDK >=3.4.3 <4.0.0 | Framework di sviluppo |
| Dart | - | Linguaggio di programmazione |
| file_picker | ^8.0.6 | Selezione file di esportazione |
| syncfusion_flutter_pdfviewer | ^23.1.39 | Visualizzazione PDF |
| ogg_opus_player | 0.7.0 | Riproduzione audio Opus |
| assets_audio_player | ^3.1.1 | Player audio alternativo |
| path | ^1.9.0 | Gestione percorsi file |

---

## Come avviare il progetto

### Prerequisiti

1. **Flutter SDK**: Installare Flutter SDK (versione 3.4.3 o superiore)
   - Scaricare da: https://docs.flutter.dev/get-started/install
2. **Editor**: VS Code o Android Studio con i plugin Flutter/Dart installati
3. **Git**: Per la gestione del codice sorgente

### Passaggi per l'avvio

#### 1. Clonare o aprire il progetto

```bash
# Se il progetto è su Git:
git clone <url_del_repository>
cd whatsapp_viewer
```

Oppure aprire direttamente la cartella del progetto nell'editor.

#### 2. Installare le dipendenze

```bash
flutter pub get
```

Questo comando scarica e installa tutte le dipendenze specificate nel file [`pubspec.yaml`](pubspec.yaml:1).

#### 3. Avviare l'applicazione

```bash
# Per Windows:
flutter run -d windows

# Per macOS:
flutter run -d macos

# Per Linux:
flutter run -d linux

# Per Android:
flutter run -d <dispositivo_android>

# Per iOS:
flutter run -d <dispositivo_ios>
```

#### 4. Utilizzo dell'applicazione

1. **Aprire un file di esportazione**: Cliccare sull'icona della cartella nella barra degli strumenti per selezionare il file `.txt` esportato da WhatsApp
2. **Inserire i nomi**: Dopo aver selezionato il file, inserire il nome del mittente e del destinatario per permettere all'app di distinguere i messaggi inviati da quelli ricevuti
3. **Navigare i messaggi**: I messaggi vengono visualizzati in un'interfaccia a bolle
4. **Visualizzare i media**:
   - Cliccare su un messaggio con allegato per aprirlo
   - Usare il pulsante "skip_next" per passare al prossimo media
   - Usare il pulsante "attach_file" per vedere l'elenco completo dei media
5. **Ricerca per testo**: Cliccare sull'icona della lente d'ingrandimento per aprire la barra di ricerca. Digitare il testo da cercare. Usare le frecce su/giù per navigare tra i risultati. I messaggi trovati vengono evidenziati in giallo.
6. **Ricerca per data**: Cliccare sull'icona del calendario per aprire il selettore di data. Il calendario è limitato all'intervallo tra il messaggio più vecchio e il più recente. Selezionare una data per trovare il messaggio più vicino a quella data.

### Struttura del file di esportazione WhatsApp

L'applicazione si aspetta un file `.txt` con il formato standard di esportazione WhatsApp:

```
GG/MM/AA, HH:MM - Nome: Testo del messaggio
GG/MM/AA, HH:MM - Nome: Immagine: IMG-XXXX.jpg (file allegato)
GG/MM/AA, HH:MM - Nome: Audio: audio_XXXX.opus (file allegato)
```

### Struttura della cartella media

I file multimediali (immagini, audio, PDF) devono trovarsi nella stessa cartella del file `.txt` oppure nella cartella genitore. L'applicazione rileva automaticamente la posizione corretta dei file media.

---

## Struttura del progetto

```
whatsapp_viewer/
├── lib/
│   └── main.dart              # Codice principale dell'applicazione
├── android/                   # Configurazione Android
├── ios/                       # Configurazione iOS
├── windows/                   # Configurazione Windows
├── linux/                     # Configurazione Linux
├── macos/                     # Configurazione macOS
├── web/                       # Configurazione Web
├── test/                      # Test dell'applicazione
├── pubspec.yaml               # Dipendenze e configurazione
└── README.md                  # Questo file
```

---

## Note

- L'applicazione è progettata principalmente per l'uso desktop (Windows, macOS, Linux)
- Il supporto per i dispositivi mobili è disponibile ma non è l'obiettivo principale
- I file media devono essere nella stessa directory del file di esportazione o nella directory genitore
