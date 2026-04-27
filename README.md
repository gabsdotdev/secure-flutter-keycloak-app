# secure-flutter-keycloak-app

Aplicativo mobile Flutter para Android e iOS com autenticação segura usando Keycloak e OAuth 2.0 / OpenID Connect com Authorization Code Flow + PKCE.

---

## Sumário

- [Funcionalidades](#funcionalidades)
- [Arquitetura](#arquitetura)
- [Pré-requisitos](#pré-requisitos)
- [Configuração do Ambiente](#configuração-do-ambiente)
- [Configuração do Keycloak](#configuração-do-keycloak)
- [Configuração Android](#configuração-android)
- [Configuração iOS](#configuração-ios)
- [Como Executar](#como-executar)
- [Segurança](#segurança)
- [Estrutura do Projeto](#estrutura-do-projeto)

---

## Funcionalidades

- ✅ Autenticação via Keycloak usando Authorization Code Flow + PKCE
- ✅ Navegador seguro do sistema (Chrome Custom Tabs / ASWebAuthenticationSession)
- ✅ Armazenamento seguro de tokens (Android Keystore / iOS Keychain)
- ✅ Refresh automático de tokens
- ✅ Logout completo (local + sessão Keycloak)
- ✅ Suporte a múltiplos ambientes (dev, staging, produção)
- ✅ Tela de splash com verificação de sessão
- ✅ Home protegida com dados do usuário
- ✅ Roteamento declarativo com go_router

---

## Arquitetura

```
lib/
├── config/
│   ├── app_config.dart           # Classe base de configuração
│   └── env/
│       ├── dev_config.dart       # Configuração de desenvolvimento
│       ├── staging_config.dart   # Configuração de homologação
│       └── prod_config.dart      # Configuração de produção
├── models/
│   └── user_model.dart           # Modelo de usuário (claims JWT)
├── services/
│   ├── auth_service.dart         # Serviço de autenticação OIDC/OAuth2
│   └── secure_storage_service.dart # Armazenamento seguro de tokens
├── providers/
│   └── auth_provider.dart        # Gerenciamento de estado (Provider)
├── router/
│   └── app_router.dart           # Navegação declarativa (go_router)
├── screens/
│   ├── splash_screen.dart        # Tela de splash
│   ├── login_page.dart           # Tela de login
│   └── home_page.dart            # Tela home protegida
├── utils/
│   └── jwt_utils.dart            # Utilitários JWT
└── main.dart                     # Ponto de entrada
```

**Bibliotecas utilizadas:**

| Biblioteca | Versão | Propósito |
|---|---|---|
| `flutter_appauth` | ^6.0.2 | OIDC/OAuth2 com PKCE via navegador seguro |
| `flutter_secure_storage` | ^9.2.2 | Armazenamento seguro (Keystore/Keychain) |
| `go_router` | ^13.2.5 | Navegação declarativa |
| `provider` | ^6.1.2 | Gerenciamento de estado |

---

## Pré-requisitos

- Flutter SDK 3.2.0+
- Dart SDK 3.2.0+
- Android Studio / Xcode para desenvolvimento mobile
- Servidor Keycloak acessível pelo dispositivo/emulador

---

## Configuração do Ambiente

### 1. Clone o repositório

```bash
git clone https://github.com/gabsdotdev/secure-flutter-keycloak-app.git
cd secure-flutter-keycloak-app
```

### 2. Instale as dependências

```bash
flutter pub get
```

### 3. Configure o ambiente

Edite o arquivo correspondente ao seu ambiente em `lib/config/env/`:

```dart
// lib/config/env/dev_config.dart
class DevConfig extends AppConfig {
  const DevConfig() : super(
    keycloakBaseUrl: 'https://seu-keycloak.exemplo.com',
    realm: 'seu-realm',
    clientId: 'seu-client-id',
    redirectUri: 'com.seu.app://callback',
    postLogoutRedirectUri: 'com.seu.app://logout',
  );
}
```

### 4. Selecione o ambiente em `main.dart`

```dart
// Para desenvolvimento:
const config = DevConfig();

// Para produção via dart-define:
const env = String.fromEnvironment('ENV', defaultValue: 'dev');
final config = switch (env) {
  'prod'    => const ProdConfig(),
  'staging' => const StagingConfig(),
  _         => const DevConfig(),
};
```

---

## Configuração do Keycloak

### 1. Crie um Client público no Keycloak

1. Acesse: **Clients → Create Client**
2. **Client type**: OpenID Connect
3. **Client ID**: `meu-app` (deve corresponder ao `clientId` na config)
4. **Client authentication**: OFF (client público, sem secret)
5. Em **Capability Config**:
   - Marque: **Standard flow** (Authorization Code)
   - Desmarque: Direct access grants, Implicit flow

### 2. Configure as URIs

Na aba **Access settings** do Client:

- **Valid redirect URIs**: `com.example.app://callback`
- **Valid post logout redirect URIs**: `com.example.app://logout`
- **Web origins**: `+` (ou a origem específica se necessário)

> ⚠️ **Segurança**: Use URIs exatas, nunca wildcards (`*`) em produção.

### 3. Escopos necessários

Certifique-se que o realm tem os escopos configurados:
- `openid` (obrigatório)
- `profile` (para nome e username)
- `email` (para e-mail)
- `offline_access` (para refresh_token)

---

## Configuração Android

### `android/app/src/main/AndroidManifest.xml`

O manifest já está configurado com os intent-filters necessários para o callback OAuth2. Substitua `com.example.app` pelo package name/scheme do seu app:

```xml
<intent-filter android:label="oauth_redirect">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="com.seu.app"
        android:host="callback" />
</intent-filter>
```

### Versão mínima do Android

Adicione em `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Mínimo para flutter_appauth e flutter_secure_storage
    }
}
```

---

## Configuração iOS

### `ios/Runner/Info.plist`

O Info.plist já está configurado com o URL scheme para callback OAuth2. Substitua `com.example.app` pelo scheme do seu app:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.seu.app</string>
        </array>
    </dict>
</array>
```

### Versão mínima iOS

Em `ios/Podfile`:
```ruby
platform :ios, '13.0'  # Mínimo para ASWebAuthenticationSession
```

### Keychain Sharing (se necessário)

Em `ios/Runner/Runner.entitlements`, adicione:
```xml
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)</string>
</array>
```

---

## Como Executar

```bash
# Desenvolvimento
flutter run

# Com seleção de ambiente
flutter run --dart-define=ENV=dev
flutter run --dart-define=ENV=staging
flutter run --dart-define=ENV=prod

# Build de produção
flutter build apk --dart-define=ENV=prod
flutter build ios --dart-define=ENV=prod
```

---

## Segurança

### Boas práticas implementadas

| Prática | Implementação |
|---|---|
| PKCE obrigatório | Gerenciado automaticamente pelo `flutter_appauth` |
| Navegador seguro do sistema | Chrome Custom Tabs (Android) / ASWebAuthenticationSession (iOS) |
| Sem WebView embutida | `flutter_appauth` usa sempre o navegador do sistema |
| Tokens em storage seguro | Android Keystore / iOS Keychain via `flutter_secure_storage` |
| Sem senha no app | Authorization Code Flow – app nunca vê a senha |
| Sem client_secret | Client público no Keycloak (adequado para apps mobile) |
| Refresh automático | `AuthService.getValidAccessToken()` com verificação de expiração |
| Logout completo | `end_session_endpoint` do Keycloak + limpeza local |
| Validação de expiração | `JwtUtils.isExpired()` com buffer de 30 segundos |

### Considerações para Produção

1. **HTTPS obrigatório**: Configure TLS 1.2+ no servidor Keycloak.

2. **Certificate Pinning**: Para máxima segurança, implemente certificate pinning:
   - Android: Use `network_security_config.xml` com `pin-set`
   - iOS: Use `TrustKit` ou `URLSession` com delegate personalizado

3. **Autorização no backend**: Lógica crítica de autorização deve estar no backend, não no app.

4. **Não exponha client_secret**: Apps mobile são clientes públicos. Nunca inclua secrets.

5. **Redirect URI exata**: Registre URIs exatas no Keycloak, nunca wildcards.

6. **Renovação de token**: O refresh token tem validade configurável no Keycloak. Após expirar, o usuário deve fazer login novamente.

### Riscos e Limitações

- **Rooting/Jailbreak**: Em dispositivos comprometidos, tokens podem ser expostos mesmo com Keystore/Keychain. Use `flutter_jailbreak_detection` para detecção.
- **Análise estática de APK**: Não inclua URLs ou configurações sensíveis hardcoded. Use variáveis de ambiente.
- **Deep link hijacking**: Prefira `https://` como scheme de redirect com App Links (Android) ou Universal Links (iOS) para mitigar hijacking de callbacks.

---

## Testes

```bash
flutter test
```

Os testes unitários cobrem:
- `UserModel`: criação a partir de claims JWT, verificação de roles
- `JwtUtils`: decodificação de payload, verificação de expiração
