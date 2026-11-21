# Autenticação e perfil

[Fluxos](README.md) · [Navegação](../configuracoes/navegacao.md) · [Armazenamento](../configuracoes/armazenamento.md#auth_session)

## Abertura

1. A splash nativa (fundo de terminal com o símbolo) aparece enquanto o Flutter carrega.
2. `SplashPage` (rota `/splash`) digita `> GastoLog` com cursor âmbar e a frase
   "Cada gasto, registrado.". Um toque pula a animação; com "remover animações" ligado
   no aparelho, o texto aparece inteiro.
3. Segue para `/` → `AuthGate`, que observa o `AuthController.status`:
   carregando → indicador; `success` → `MainShell`; `empty`/`error` → `LoginPage`.

## Login (fake)

**Entrada:** `AuthGate` sem sessão salva.

1. Usuário informa e-mail e senha.
2. `Login` valida: e-mail em formato válido e senha com **4 ou mais** caracteres.
   Não existe conferência de senha.
3. `FakeAuthRepository.login`:
   - e-mail já usado neste aparelho → recupera o mesmo perfil;
   - e-mail novo → cria o usuário (nome = parte antes do `@`, com inicial maiúscula).
4. Grava o perfil e a chave `currentUserId`; `AuthGate` troca para o `MainShell`.
5. Ao reabrir o app, a sessão é restaurada e o login é pulado.

## Perfil e sair

**Entrada:** Mais → card da conta, ou Configurações → Conta → Perfil.

| Ação | Etapas | Efeito atual |
|---|---|---|
| Ver perfil | — | nome, e-mail, avatar com iniciais, data de cadastro |
| Editar perfil | sheet com nome/e-mail → salvar | `UpdateProfile` valida e grava no Hive |
| Sair | confirmar | `Logout` apaga só `currentUserId`; o perfil fica salvo para um próximo login com o mesmo e-mail |

**Dados atuais:** box `auth_session`. Os dados do app (Boxes, produtos...) **não** são
por usuário: outra conta no mesmo aparelho vê os mesmos dados. Só o plano é por usuário.

Para trocar por autenticação real: implemente `AuthRepository` (ex.: `ApiAuthRepository`)
e registre no lugar do `FakeAuthRepository` em `InitialBinding`. Telas e controller
dependem só da interface.

| Alterar | Fonte |
|---|---|
| Validação do login | [login.dart](../../lib/features/auth/domain/usecases/login.dart) |
| Sessão e criação de perfil | [fake_auth_repository.dart](../../lib/features/auth/data/repositories/fake_auth_repository.dart) |
| Estado da sessão | [auth_controller.dart](../../lib/features/auth/presentation/controllers/auth_controller.dart) |
| Telas | [login_page.dart](../../lib/features/auth/presentation/pages/login_page.dart), [profile_page.dart](../../lib/features/auth/presentation/pages/profile_page.dart) |
| Decisão login × app | [auth_gate.dart](../../lib/app/navigation/auth_gate.dart) |
| Animação de abertura | [splash_page.dart](../../lib/app/navigation/splash_page.dart) |
