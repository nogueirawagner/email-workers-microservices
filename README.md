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

<span style='color: rgb(0, 0, 0);'>Testando cor</span> <p><b>Perceba que já temos duas portas expostas para o mundo real e isso não é bom. Não faz sentido deixar a porta do app exposta sendo que apenas o nginx deve acessá-lo internamente. Para isso vamos configurar o que é chamado de Proxy Reverso no nginx e esconder a porta do app.</b></p>
