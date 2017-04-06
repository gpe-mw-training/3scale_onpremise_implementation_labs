package io.vertx.blog;

import io.vertx.core.AbstractVerticle;
import io.vertx.core.json.JsonObject;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.handler.StaticHandler;
import io.vertx.util.Runner;

public class App extends AbstractVerticle {

  private static final String LISTENER_PORT="LISTENER_PORT";

  public static void main(String[] args) {
    Runner.run(App.class);
  }

  @Override
  public void start() {

    int port = 8080;
    String portString = System.getProperty(LISTENER_PORT);
    if(portString != null && !portString.equals("")) 
        port = Integer.parseInt(portString);

    System.out.println("start() port this service will bind to: "+port);

    Router router = Router.router(vertx);

    router.get("/hello").handler(rc -> {
      rc.response()
          .putHeader("content-type", "application/json")
          .end(new JsonObject().put("greeting", "Hello World!").encode());
    });

    // optionally enable the web console so users can play with your API
    // online from their web browsers
    router.route().handler(StaticHandler.create());

    vertx.createHttpServer().requestHandler(router::accept).listen(port);
  }
}
