# PudimHub — Fling Things and People

Execute pelo carregador universal:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Pudimlinoo/PudimHub/main/script.lua"))()
```

Todas as funções opcionais começam desligadas. Controles para teclado e mouse.

| Aba | Recursos |
| --- | --- |
| Início | Avatar, nome, time, vida, movimento, FPS e sessão |
| Player | Velocidade e pulo extras, voo, noclip, pulo no ar, limite anti-fling, resgate de queda, freio |
| Arremesso | Impulso extra, elevação, giro, direção e contorno do objeto segurado |
| Mira | Q segurado, corpo/cabeça, raio, alcance, suavização, antecipação, paredes, time e alvo persistente |
| ESP | Contornos, nomes, distância, vida e oclusão; até 25 jogadores |
| Teleporte | Três posições salvas, seleção de jogadores, observação e teleporte no cursor |
| Visual | Mira central, iluminação e campo de visão |
| Ajustes | Escala, atalhos e restauração dos padrões |

## Atalhos

- **H**: abrir/fechar painel; o mouse fica livre com ele aberto.
- **G**: voo. **WASD**, **Espaço** e **Ctrl esquerdo** controlam o voo.
- **Q segurado**: mira assistida, quando ativada e com o painel fechado.
- **V**: teleporte no cursor, quando ativado; aponte para chão horizontal.
- **X**: frear movimento e rotação do personagem.

Velocidade/pulo em **0** preservam os valores originais. Parar tudo desliga as funções e restaura colisões, iluminação, FOV e câmera observada. Encerrar também remove o HUD e suas conexões.

## Super força

Ative Super força, feche o painel, pegue um objeto com o botão esquerdo e arremesse com o direito. O script correlaciona o objeto clicado com `GrabParts/GrabPart/WeldConstraint.Part1`. Somente a remoção desse vínculo com uma intenção recente de arremesso aplica o impulso. Soltar com o botão esquerdo não aplica força extra.

O controle é um acréscimo de velocidade em studs/s, convertido em impulso usando a massa da montagem. Elevação e giro são independentes. O indicador da aba informa se reconheceu o vínculo; se a estrutura do jogo mudar, a função não inventa eventos remotos.

## Limitações e verificação

A física de objetos depende da propriedade de rede. Um impulso local pode não se propagar ou ser corrigido pelo servidor. Noclip, teleporte e alterações do personagem também podem ser corrigidos. A previsão de mira é linear, ajustável em milissegundos; não garante acerto balístico. Anti-fling limita velocidade, não impede agarrões. O resgate precisa de um chão firme registrado antes da queda e não impede mortes instantâneas.

Validação local: compilação Luau e testes isolados de intenção/impulso de arremesso, restauração do cursor e valores base de movimento. Não foi feita validação dentro de uma sessão Roblox.

Para validar no jogo: testar uma função por vez, confirmar que deixar um objeto com o botão esquerdo não o arremessa, testar arremesso com direito, abrir H enquanto segura Q, desligar ESP, alternar observação e usar Parar tudo. Conferir os valores originais após encerrar e repetir após respawn.

## Referências consultadas

- [Experiência oficial de Horomori](https://www.roblox.com/games/6961824067/Fling-Things-and-People).
- [Propriedade de rede e física — Roblox](https://create.roblox.com/docs/physics/network-ownership).
- [BasePart / ApplyImpulse — Roblox](https://create.roblox.com/docs/reference/engine/classes/BasePart).
- [Referência pública da estrutura GrabParts](https://github.com/FACEME-txt/SolaraSCRIPTS/blob/main/Fling%20Things%20And%20People%20%28STRENGTH%20Script%29).
- [Segunda ocorrência pública da estrutura](https://github.com/753eml/ftap/blob/main/ftap.lua).

As fontes de terceiros foram lidas como referência, não executadas nem carregadas pelo hub. Sua estrutura não é uma API oficial do jogo.
