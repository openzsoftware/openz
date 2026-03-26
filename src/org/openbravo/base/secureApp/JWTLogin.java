package org.openbravo.base.secureApp;

import java.io.IOException;
import java.io.PrintWriter;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;
import org.codehaus.jettison.json.JSONException;
import org.codehaus.jettison.json.JSONObject;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;

import org.openbravo.service.db.DalConnectionProvider;

public class JWTLogin extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static Logger log4j = Logger.getLogger(JWTLogin.class);

    @Override
    public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
        String message = "";
        int message_no = 0;
        String username = "";
        String jwt = "";
        String exception_msg = "";
        final Map<Integer, String> errorMessages = new HashMap<Integer, String>();
            // 0 -> success
            errorMessages.put(0, "Authentication via JWT successfull. Login Cookie set.");
            // everything else -> fail
            errorMessages.put(1, "JWT Login is disabled.");
            errorMessages.put(2, "No authorization token found. Required syntax (Bearer <Signed JWT>).");
            errorMessages.put(3, "Athorization does not meet the required syntax (Bearer <Signed JWT>).");
            errorMessages.put(4, "User not found or deactivated with given name.");
            errorMessages.put(5, "JSON Web Token could not be verified.");
            errorMessages.put(10, "Exception thrown.");

        if(JWTLoginData.apiActive(new DalConnectionProvider()).equals("Y")) {
            jwt = request.getHeader("Authorization");
            // no record for given searchkey
            if(jwt == null || jwt.isEmpty()) {
                message_no = 2;
            } else if(!jwt.startsWith("Bearer")) {
                message_no = 3;
            } else {
                jwt = jwt.replaceAll("Bearer ", "");
            }
        } else {
            message_no = 1;
        }

        // 0 -> success
        if(message_no == 0) {
            // it is possible to insert multiple public keys
            for(JWTLoginData key : JWTLoginData.getPublicKeys(new DalConnectionProvider())) {
                exception_msg = "";
                try {
                    final String PUBLIC_KEY_PEM = key.publickey;
                    PublicKey publicKey = loadPublicKey(PUBLIC_KEY_PEM);
                    Algorithm algorithm = Algorithm.RSA256((java.security.interfaces.RSAPublicKey)publicKey, null);
                    JWTVerifier verifier = JWT.require(algorithm)
                                              .withAudience(key.aud) // audience has to match
                                              .withIssuer(key.iss)   // issuer has to match
                                              .acceptExpiresAt(5)    // expiration time 5 seconds leeway
                                              .build();
                    DecodedJWT jwt_dec = verifier.verify(jwt);
                    // field exp not present
                    if(jwt_dec.getExpiresAt() == null) {
                        throw new JWTVerificationException("The claim 'exp' has to be present with a numeric date value.");
                    }
                    username = jwt_dec.getSubject();
                    // Signature is valid -> Log in User
                    final String strUserAuth = JWTLoginData.getUserId(new DalConnectionProvider(), username);
                    if(strUserAuth != null && !strUserAuth.isEmpty()) {
                        // sets the session cookie (JSESSIONID) for the authenticated user
                        request.getSession(true).setAttribute("#Authenticated_user", strUserAuth);
                        message_no = 0; // success
                        break;
                    } else {
                        message_no = 4;
                        break;
                    }
                }catch (JWTVerificationException e) {
                    message_no = 5;
                    exception_msg = e.getMessage();
                } catch (Exception e) {
                    message_no = 10;
                    exception_msg = e.getMessage();
                }
            }
        }

        JSONObject json = new JSONObject();
        message = errorMessages.get(message_no);
        try {
            json.put("username", username);
            json.put("success", message_no == 0);
            json.put("message_no", message_no);
            json.put("message", message);
            json.put("exception_msg", exception_msg);
        } catch(JSONException e) {
            // do nothing, cant be reached
        }

        response.setCharacterEncoding("utf-8");
        response.setContentType("application/json");
        PrintWriter wr = response.getWriter();
        wr.write(json.toString());
        wr.flush();
    }
    
    private static PublicKey loadPublicKey(String pem) throws Exception {
        String key = pem.replace("-----BEGIN PUBLIC KEY-----", "")
                     .replace("-----END PUBLIC KEY-----", "")
                     .replaceAll("\\s+", "");
        byte[] encoded = Base64.getDecoder().decode(key);
        X509EncodedKeySpec keySpec = new X509EncodedKeySpec(encoded);
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        return keyFactory.generatePublic(keySpec);
    }
}
