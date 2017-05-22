package org.wildfly.swarm.examples.jaxrs.swagger;

import java.security.Principal;
import javax.servlet.http.HttpServletRequest;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Context;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.joda.time.DateTime;

@Path("/time")
@Api(value = "/time", description = "Get the time", tags = "time")
@Produces(MediaType.APPLICATION_JSON)
public class TimeResource {

    @GET
    @Path("/now")
    @ApiOperation(value = "Get the current time",
            notes = "Returns the time as a string",
            response = String.class
    )
    @Produces(MediaType.APPLICATION_JSON)
    public String get(@Context HttpServletRequest request) {

        Principal principal = request.getUserPrincipal();
        if(principal != null) {
            String pName = principal.getName();
            System.out.println("get() pName = "+pName+" : principal class type = "+principal.getClass().toString());
        }else {
            System.out.println("get() principal not found ");
        }

        return String.format("{\"value\" : \"The time is %s\"}", new DateTime());
    }
}
