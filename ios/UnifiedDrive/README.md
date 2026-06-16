# UnifiedDrive iOS

Client iOS nativo SwiftUI per un filesystem WebDAV raggiunto tramite Tailscale.

Target minimo: iOS 16. Compatibile con iOS piu recenti, incluso iOS 26 quando compilato con SDK aggiornato.

## Cosa include

- Onboarding con codice `IP|password`, utente fisso `ud` e verifica `PROPFIND /`.
- Salvataggio della configurazione nel Keychain.
- Browser WebDAV con `PROPFIND Depth: 1`, dimensione, data, icone per tipo e pull-to-refresh.
- Apertura immagini e PDF tramite anteprima Quick Look.
- Streaming audio/video con `AVPlayer` e header Basic Auth.
- Download e share sheet per gli altri file.
- Upload da Files e Foto con `PUT`.
- Creazione cartelle con `MKCOL`, rinomina con `MOVE`, eliminazione con `DELETE`.
- Cache locale dei file aperti di recente, disponibile quando l'hub non risponde.
- Indicatore online/offline.
- Design stile Finder/iCloud Drive con griglia, lista, ricerca, ordinamento, breadcrumb, metriche e menu contestuali.
- Liquid Glass su iOS 26 tramite API native, con fallback `.ultraThinMaterial` sulle versioni precedenti.

## Aprire il progetto

1. Copia o apri questa cartella su un Mac con Xcode 15 o successivo:
   `C:\Users\user\UnifiedDrive\ios\UnifiedDrive`
2. Apri `UnifiedDrive.xcodeproj`.
3. Seleziona lo schema `UnifiedDrive`.
4. Per il simulatore, scegli un simulatore iOS 16+ e premi Run.
5. Per iPhone reale:
   - collega l'iPhone al Mac;
   - in Xcode seleziona il dispositivo;
   - in `Signing & Capabilities` scegli il tuo Team Apple;
   - se necessario cambia `Bundle Identifier` da `com.local.UnifiedDrive` a un valore unico;
   - premi Run.

## Uso

1. Installa e accedi a Tailscale sull'iPhone.
2. Verifica che l'hub WebDAV sia raggiungibile dal tailnet, per esempio `http://100.101.102.103:8087`.
3. Avvia UnifiedDrive.
4. Incolla un codice nel formato:

   ```text
   100.101.102.103|abc123
   ```

5. Tocca `Connetti`.

## Note tecniche

- L'app consente HTTP in `Info.plist` per supportare l'endpoint Tailscale `http://100.x.y.z:8087`.
- Non usa dipendenze esterne: solo SwiftUI, URLSession, XMLParser, Keychain, QuickLook, AVKit e PhotosUI.
- Le API Liquid Glass sono isolate dietro controlli di compilatore/disponibilita: Xcode vecchi usano il fallback Material, Xcode con SDK iOS 26 abilita `glassEffect` e `GlassEffectContainer`.
- La File Provider Extension non e inclusa in questo scaffold per mantenere il target immediatamente compilabile. Per far apparire UnifiedDrive nell'app File servono entitlement specifici, App Group e provisioning nel Developer Portal Apple.

## Debug fatto in questa workspace

- Verificato che tutti i file Swift siano referenziati nel target Xcode.
- Verificato che `Info.plist` sia XML valido.
- Verificati i JSON degli asset catalog.
- Rimossi riferimenti diretti a API iOS 17/26 non protette.
- Aggiunto e lanciato `Scripts/validate-ios-project.ps1` per rendere ripetibili questi controlli.

La build runtime va eseguita su Mac con Xcode, perche in questa workspace Windows non e disponibile `xcodebuild`.

## IPA per sideload

Questa repo include un workflow GitHub Actions:

```text
.github/workflows/build-unifieddrive-ipa.yml
```

Modalita:

- `unsigned`: produce `UnifiedDrive-unsigned.ipa`, pensato per strumenti che rifirmano l'IPA durante il sideload.
- `signed`: produce un IPA firmato usando certificato `.p12` e provisioning profile inseriti nei secrets del repository.

Secrets per `signed`:

- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`
- `APPLE_TEAM_ID`
- `IOS_PROFILE_NAME`
- `IOS_BUNDLE_ID`
- `IOS_EXPORT_METHOD` opzionale, per esempio `development` o `ad-hoc`

Su un Mac con Xcode puoi anche usare:

```bash
cd ios/UnifiedDrive
Scripts/build-unsigned-ipa.sh
```

## Zip per Appetize

Appetize richiede una build iOS Simulator `.app` compressa in `.zip`, non un `.ipa` device.
Questa repo include il workflow:

```text
.github/workflows/build-appetize-simulator-zip.yml
```

Avvialo da GitHub Actions e scarica l'artifact:

```text
UnifiedDrive-Appetize-iOS-Simulator.zip
```

Quel file e quello da caricare su Appetize.

Se aggiungi il secret GitHub `APPETIZE_API_TOKEN`, il workflow aggiorna anche direttamente
l'app Appetize esistente:

```text
vkslgigx6zyzqihozz7ugb6uhq
```

Puoi sovrascrivere la destinazione con il secret opzionale `APPETIZE_PUBLIC_KEY`.

Su un Mac con Xcode puoi produrre lo stesso zip con:

```bash
cd ios/UnifiedDrive
Scripts/build-appetize-zip.sh
```
