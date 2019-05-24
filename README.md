# email-workers-microservices

Enviar e-mail com workers utilizando microservices em containers docker.

O objetivo deste exemplo é simular uma solução assíncrona e escálavel para envio de e-mails, que será baseada em containers docker e filas.
Este exemplo utilizará as seguintes imagens listadas na imagem abaixo:

<image src="https://github.com/nogueirawagner/email-workers-microservices/blob/master/images/Email.png"/>

O fluxo começa em uma página HTML muito simples, que tem um formulário com dois campos o título da mensagem e o corpo da mensagem.
O frontend utilizando um proxy reverso encaminha a requisição para o app e quando a mensagem chega no app ela é persistida no banco de dados para fins de registros e ao mesmo tempo é registrada na fila baseada no redis.
Uma vez que a fila começa a ter mensagens a serem processadas, os workers fará uma chamada para a fila e começa a processar o registro.

Todos estes containers serão montados a partir do docker compose.
