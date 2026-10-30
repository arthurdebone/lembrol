# Lembrol — Gerenciador de Lembretes Recorrentes Pessoais (Local-First)

**Lembrol** é um aplicativo móvel e desktop desenvolvido em **Flutter** e **Dart**, projetado para pessoas que precisam de lembretes regulares de saúde, ergonomia e foco — como beber água a cada hora, descansar os olhos a cada 40 minutos ou levantar da cadeira periodicamente.

O aplicativo funciona de forma **100% local**:
- Sem cadastros ou autenticação.
- Sem dependência de servidores ou nuvem.
- Sem necessidade de conexão com a internet.
- Persistência em banco de dados SQLite local via Drift.

---

## 1. Arquitetura do Projeto (Clean Architecture)

O projeto adota os princípios de Clean Architecture com separação rigorosa de responsabilidades:

```
lib/
├── core/
│   ├── clock.dart                 # Relógio injetável (AppClock / SettableClock) para testes
│   ├── constants/
│   │   ├── app_constants.dart     # Constantes gerais (canais, snoozes, categorias)
│   │   └── app_templates.dart     # Modelos de fábrica (Água, Olhos, Postura)
│   ├── theme/
│   │   └── app_theme.dart         # Material 3 com suporte a temas Claro e Escuro
│   ├── utils/
│   │   └── time_formatters.dart   # Formatadores de data, hora e contagem regressiva
│   └── router/
│       └── app_router.dart        # Navegação declarativa com GoRouter
├── domain/
│   ├── entities/
│   │   ├── reminder.dart          # Entidade central do lembrete
│   │   ├── reminder_log.dart      # Histórico observável de eventos
│   │   └── app_settings.dart      # Preferências do usuário
│   ├── recurrence/
│   │   ├── recurrence_engine.dart # Motor matemático de cálculo de disparos
│   │   └── recurrence_validator.dart # Validações de título, horários e dias
│   └── repositories/
│       ├── reminder_repository.dart
│       ├── history_repository.dart
│       └── settings_repository.dart
├── data/
│   ├── datasources/
│   │   ├── database.dart          # Definição das tabelas Drift (SQLite)
│   │   └── database.g.dart        # Código gerado pelo drift_dev
│   ├── models/
│   │   ├── reminder_mapper.dart   # Conversão Drift Row <-> Entidade Reminder
│   │   └── history_mapper.dart    # Conversão Drift Row <-> Entidade ReminderLog
│   └── repositories/
│       ├── reminder_repository_impl.dart
│       ├── history_repository_impl.dart
│       └── settings_repository_impl.dart
├── platform/
│   ├── notifications/
│   │   ├── notification_service.dart       # Contrato de notificações
│   │   └── local_notification_service.dart # Notificações Android e Windows
│   ├── scheduler/
│   │   └── reminder_scheduler_service.dart # Orquestrador independente de disparos
│   ├── permissions/
│   │   └── permission_manager.dart         # Diagnóstico de permissões do SO
│   └── autostart/
│       └── autostart_service.dart          # Inicialização automática no Windows
└── presentation/
    ├── providers/
    │   └── app_providers.dart     # Provedores Riverpod (Injeção de Dependências e Streams)
    ├── screens/
    │   ├── dashboard/             # Tela inicial com contagem regressiva e ações rápidas
    │   ├── reminders/             # Listagem, formulário (com prévia) e detalhes
    │   ├── history/               # Histórico auditável com filtros de status
    │   └── settings/              # Configurações, temas, autostart e diagnóstico
    └── widgets/
        ├── day_selector.dart      # Seletor interativo de dias da semana
        ├── permission_banner.dart # Banner de aviso de permissões
        ├── template_picker_dialog.dart # Seletor de modelos de lembretes
        └── responsive_scaffold.dart    # Layout adaptativo (Sidebar Desktop / Bottom Bar Mobile)
```

---

## 2. Tecnologias e Dependências Utilizadas

| Pacote | Versão | Finalidade |
|---|---|---|
| `flutter_riverpod` | `^2.6.1` | Gerenciamento de estado reativo, imutável e injeção de dependências. |
| `go_router` | `^14.8.1` | Roteamento declarativo com suporte a rotas aninhadas e parâmetros. |
| `drift` + `drift_dev` | `^2.24.2` | ORM SQLite type-safe com geração de código e queries reativas via streams. |
| `sqlite3_flutter_libs` | `^0.5.28` | Binários compilados do SQLite (NDK para Android e `sqlite3.dll` para Windows). |
| `flutter_local_notifications` | `^18.0.1` | Alarmes exatos no Android com canais de alta prioridade e receivers de boot. |
| `local_notifier` | `^0.1.6` | Toasts nativos no Windows Desktop via WinRT Toast Notifications. |
| `timezone` | `^0.9.4` | Cálculo preciso de horários locais e conversões de fuso. |
| `win32` | `^6.0.0` | Integração profunda com o Registro do Windows para inicialização automática. |
| `uuid` | `^4.5.1` | Geração de identificadores únicos persistentes (UUID v4). |
| `intl` | `^0.20.2` | Formatação de datas e horas em padrão pt-BR. |
| `clock` | `^1.1.2` | Relógio virtual controlável para testes determinísticos. |

---

## 3. Instalação e Execução

### Pré-requisitos
- Flutter SDK 3.44.x ou superior
- Dart SDK 3.12.x ou superior

### Passos de Execução

1. **Obter as dependências:**
   ```bash
   flutter pub get
   ```

2. **Gerar os arquivos do banco de dados (Drift):**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Executar a aplicação:**
   - No Windows Desktop:
     ```bash
     flutter run -d windows
     ```
   - No Android (emulador ou aparelho físico conectado com depuração USB):
     ```bash
     flutter run -d android
     ```

---

## 4. Instruções para Compilação e Distribuição

### 4.1. Android

#### Gerar APK de Release:
```bash
flutter build apk --release
```
O arquivo gerado estará em: `build/app/outputs/flutter-apk/app-release.apk`.

#### Gerar App Bundle (Google Play):
```bash
flutter build appbundle --release
```
O arquivo gerado estará em: `build/app/outputs/bundle/release/app-release.aab`.

### 4.2. Windows Desktop

#### Pré-requisito para compilação Windows:
O compilador C++ da Microsoft é necessário para compilar o executável nativo do Windows:
- Instale o **Visual Studio Build Tools** com a carga de trabalho *"Desenvolvimento para Desktop com C++"*.
- Pode ser instalado rapidamente pelo terminal via winget:
  ```powershell
  winget install Microsoft.VisualStudio.2022.BuildTools --override "--passive --add Microsoft.VisualStudio.Workload.VCTools"
  ```

#### Compilar Executável do Windows:
```bash
flutter build windows --release
```
O executável compilado e seus arquivos auxiliares estarão em: `build/windows/x64/runner/Release/`.

#### Gerar Instalador MSIX (Opcional):
Para empacotar como um instalador MSIX moderno para a Microsoft Store ou distribuição direta:
```bash
dart run msix:create
```

---

## 5. Permissões e Configurações por Plataforma

### 5.1. Android (`android/app/src/main/AndroidManifest.xml`)
- `RECEIVE_BOOT_COMPLETED`: Permite ao Lembrol reconstruir a agenda de disparos após o reinício do dispositivo.
- `SCHEDULE_EXACT_ALARM` e `USE_EXACT_ALARM`: Permite disparos com precisão ao segundo, contornando suspensões do Doze Mode.
- `POST_NOTIFICATIONS`: Permissão de exibição de avisos visuais no Android 13+ (API 33).
- `VIBRATE`: Permite acionar vibração háptica nos disparos.
- `WAKE_LOCK`: Garante que a CPU processe o evento no exato momento programado.

> **Nota sobre Economia de Bateria (OEM Doze):** Em aparelhos Xiaomi (MIUI), Samsung (OneUI) e Huawei, orienta-se o usuário nas configurações a definir o Lembrol como "Sem restrições de bateria" para que o sistema operacional não suspenda os alarmes em segundo plano.

### 5.2. Windows Desktop
- **Notificações:** Utilizam a API WinRT Toast Notifications (`local_notifier`).
- **Autostart:** O aplicativo pode ser configurado na tela de Ajustes para registrar a chave `Lembrol` em `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, iniciando minimizado com o login do usuário.
- **Limitação Conhecida:** Caso o computador esteja desligado, o sistema operacional não executa alertas passados. Ao religar o computador e abrir o app, os alarmes perdidos são catalogados e os próximos são recalculados imediatamente.

---

## 6. Relatório dos Testes Automatizados Executados

O projeto conta com uma suíte de testes com **21 testes automatizados**, todos aprovados com 100% de sucesso.

### 6.1. Motor de Recorrência (`test/domain/recurrence_engine_test.dart`)
1. **Cenário 1:** Início às 08:00, fim às 12:00 e intervalo de 60 minutos (5 disparos exatos: 08:00, 09:00, 10:00, 11:00, 12:00).
2. **Cenário 2:** Início às 08:00, fim às 10:00 e intervalo de 45 minutos (3 disparos: 08:00, 08:45, 09:30).
3. **Cenário 3:** Disparo exatamente no horário final (inclusivo).
4. **Cenário 4:** Intervalo que não divide a janela perfeitamente.
5. **Cenário 5:** Dias da semana selecionados e não selecionados (respeita dias úteis vs fim de semana).
6. **Cenário 6:** Lembrete desativado não gera novos disparos.
7. **Cenário 7:** Edição do intervalo recalcula disparos corretamente.
8. **Cenário 8:** Edição dos horários inicial e final.
9. **Cenário 9:** Cancelamento de agendamentos ao desativar ou deletar.
10. **Cenário 10:** Lembretes simultâneos no mesmo horário sem conflito de IDs.
11. **Cenário 11:** Adiamento (snooze de 5, 10, 15 min) sem alterar a grade da sequência regular.
12. **Cenário 12:** Mudança de data ou horário do sistema (reavaliação imediata e determinística).
13. **Cenário 13:** Reconstrução determinística dos agendamentos após reinicialização.
14. **Cenário 14:** Validação de horários e intervalos inválidos (start >= end, intervalo <= 0, etc.).

### 6.2. Testes de Widgets (`test/presentation/`)
15. **Dashboard Vazio:** Exibição amigável de estado vazio com botões para novo lembrete e modelos.
16. **Dashboard com Lembretes:** Listagem e cartões de lembretes ativos com contagem.
17. **Formulário de Cadastro:** Renderização de todos os campos essenciais e prévia em tempo real.
18. **Validação de Título:** Bloqueio de salvamento e mensagem clara se o título estiver vazio.
19. **Validação de Intervalo:** Bloqueio de salvamento se o intervalo for zero ou negativo.
20. **Interação com Dias:** Funcionamento dos atalhos "Todos", "Úteis", "Fim de sem." e chips de tempo.
21. **Modo Edição:** Pré-carregamento fiel de todos os dados do lembrete existente.

Para rodar os testes:
```bash
flutter test
```
Resultado: **All 21 tests passed!**
