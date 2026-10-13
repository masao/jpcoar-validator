import com.sun.net.httpserver.HttpServer;

import net.sf.saxon.s9api.*;

import javax.xml.transform.stream.StreamSource;
import java.io.*;
import java.net.InetSocketAddress;

public class ValidatorServer {
    public static void main(String[] args) throws Exception {
        Processor processor = new Processor(false);

        XsltCompiler compiler = processor.newXsltCompiler();
        XsltExecutable validator = compiler.compile(
            new StreamSource("xslt/jpcoar2.0.xsl")
        );

        HttpServer server = HttpServer.create(
            new InetSocketAddress("127.0.0.1", 9000),
            0
        );

        server.createContext("/validate", exchange -> {
            try {
                XsltTransformer transformer = validator.load();

                transformer.setSource(
                    new StreamSource(exchange.getRequestBody())
                );

                ByteArrayOutputStream output =
                    new ByteArrayOutputStream();

                Serializer serializer =
                    processor.newSerializer(output);

                transformer.setDestination(serializer);
                transformer.transform();

                byte[] body = output.toByteArray();

                exchange.getResponseHeaders().set(
                    "Content-Type",
                    "application/xml; charset=UTF-8"
                );

                exchange.sendResponseHeaders(200, body.length);

                try (OutputStream response =
                         exchange.getResponseBody()) {
                    response.write(body);
                }
            } catch (Exception e) {
                byte[] body = e.getMessage().getBytes();

                exchange.sendResponseHeaders(500, body.length);

                try (OutputStream response =
                         exchange.getResponseBody()) {
                    response.write(body);
                }
            }
        });

        server.createContext("/health", exchange -> {
            byte[] response = "OK".getBytes(
                java.nio.charset.StandardCharsets.UTF_8
            );
            exchange.sendResponseHeaders(200, response.length);
            try (var output = exchange.getResponseBody()) {
                output.write(response);
            }
        });
        server.start();

        System.err.println(
            "JPcoar validator listening on 127.0.0.1:9000"
        );
    }
}