# email-workers-microservices

Enviar e-mail com workers utilizando microservices em containers docker.

O objetivo deste exemplo é simular uma solução assíncrona e escálavel para envio de e-mails, que será baseada em containers docker e filas.
Este exemplo utilizará as seguintes imagens listadas na imagem abaixo:

<image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/Email.png"/>

O fluxo começa em uma página HTML muito simples, que tem um formulário com dois campos o título da mensagem e o corpo da mensagem.
O frontend utilizando um proxy reverso encaminha a requisição para o app e quando a mensagem chega no app ela é persistida no banco de dados para fins de registros e ao mesmo tempo é registrada na fila baseada no redis.
Uma vez que a fila começa a ter mensagens a serem processadas, os workers fará uma chamada para a fila e começa a processar o registro.

Todos estes containers serão montados a partir do docker compose.

<h1>Iniciando a composição do banco</h1>
<p>Executando o <b>docker-compose up -d</b> para rodar o container no modo daemon.</p>
<p>Executando o comando dentro do serviço db definindo o usuário com -U "postgres" e o comando com -c '\l'. <br/> 
Este comando é para listar os banco de dados dentro da instância. <br/> 
<b>docker-compose exec db psql -U postgres -c '\l'</b></p>

<image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/db.png"/>

<h1> Scripts de Inicialização </h1>
<p>O script de inicialização init.sql está dentro da pasta scripts, e foi mapeado para dentro do volume criado para o container na pasta scripts.</p>

<image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/volume-db.png"/>
<p> Foi criado o arquivo check.sql também dentro da pasta scripts para checar se foi criado a tabela e o banco de dados.
  No script tem três comandos:</p>
<p> <b>\l</b> que é pra listar os bancos de dados existentes neste momento já deve ser listado o banco email_sender. </p>
<p><b> \c email_sender </b> para conectar no banco </p>
<p> <b>\d emails </b> para mostrar uma descrição da tabela emails</<p>
  
<p>Para rodar o arquivo check.sql execute o comando <b>docker-compose exec db psql -U postgres -f /scripts/check.sql</b></p>

<h1>Criando o serviço front end com nginx.</h1>
<p>Adiciona mais um serviço no docker-compose.yml, aponta a pasta do diretório host que contém a página html, define a porta 80:80 que já é a padrão e aponta pra imagem do nginx:1.13</p>
<image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/frontend.png"/>
<image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/index.png"/>

<h1>Criando o servidor em Python para receber as mensagens do nginx</h1>
<p>Foi definido o método POST que será acessado na rota padrão localhost:8080
A requisição será enviada pelo nginx diretamente para esta rota, ao receber a mensagem irá retornar a mensagem formatada na porta 8080.
</p>
<p>Para isso criamos um novo serviço no arquivo docker-compose.yml baseado na imagem do python e apontamos para a porta 8080, e criamos o seu volume passando a pasta app.</p>
<image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/compose-py.png"/>
<p>Acessando a URL localhost:80 estamos consumindo o serviço do nginx e recebendo a resposta pela porta 8080 do serviço app.</p>
 
 <image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/sender.png"/>
<image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/python.png"/>

<p><b>Perceba que já temos duas portas expostas para o mundo real e isso não é bom. Não faz sentido deixar a porta do app exposta sendo que apenas o nginx deve acessá-lo internamente. Para isso vamos configurar o que é chamado de Proxy Reverso no nginx e esconder a porta do app.</b></p>

<h1>Configurando proxy reverso </h1>
<p>A configuração foi feita dentro do arquivo default.conf dentro da pasta nginx. <br/>
Sempre que chegar uma requisição para /api vai fazer um proxy para http://app:8080/ exatamente a porta que foi definida no arquivo de sender em python, e app é o nome do serviço que definimos para o nome do serviço lá no docker-compose.yml<br/>
</p>

<image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/default.png"/>

<p>O que precisa de fazer agora é no serviço do frontend criar um volume para ler a configuração do proxy reverso dentro do container.<br>
  Enviando o arquivo default.conf para dentro do container nginx, e no serviço app retirar a porta 8080. <br/>
  Desta forma a única porta que fica exposta é a 80 do container do frontend.
</p>
<image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/front-reverso.png"/>

<p>Agora no index.html faz um pequeno ajuste na ação do formulário, não apontando mais para localhost:8080 e sim para localhost/api.</p>
<image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/index-reverso.png"/>

<p>Veja o comportamento de quando o formulário envia a requisição agora para a rota localhost/api </p>
<image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/web-reverso.png"/>

<p><b>Preste atenção na URL, agora de fato está usando o proxy reverso e não preciso mais expor a porta 8080 e a aplicação app não está mais disponível, fornecendo mais segurança.</b><p>
  
 <h1>Processando a fila de mensagens gravada no Redis</h1>
 
 <p>Neste exemplo executando docker-compose up -d irá subir cada container com o seu serviço, apenas uma instância</p>
 <image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/worker1.png"/>
 </br>
 
 <h1> Escalar é preciso</h1>
 <p>Como criamos um serviço por contâiner fica muito mais fácil escalar um serviço em específico. </br>
 Precisamos escalar o serviço de worker, para quantas instâncias quisermos.</p>
 <p>Para isso veja as alterações sofridas no docker-compose e a criação do arquivo Dockerfile dentro da pasta worker.</p>
 <p>Com para escalar o serviço de worker utilizará a flag --scale passando o nome do serviço e a quantidade de instâncias que queremos.</br>
 O comando então fica assim: docker-compose up -d --scale worker=3</p>
 <p>Na imagem abaixo ao executar o compose vemos que foi criado mais de uma instância para o serviço worker</p>
 
 <image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/compose-3.png"/>
 </br>
 <p>Veja agora o processamento assíncrono de cada serviço, a medida que a mensagem vai entrando na fila da Redis o worker livre processa a imagem.</p>
 <p>Para monitorar somente os logs do serviço o worker: docker-compose logs -f -t worker</p>
 <image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/worker3.png"/>
 
