import java.util.ArrayList;
import java.util.Collections;

//these are variables you should probably leave alone
int index = 0; //starts at zero-ith trial
float border = 0; //some padding from the sides of window
int trialCount = 12; //this will be set higher for the bakeoff
int trialIndex = 0; //what trial are we on
int errorCount = 0;  //used to keep track of errors
float errorPenalty = 0.5f; //for every error, add this value to mean time
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false; //is the user done

boolean mouseDragged = false;
float mouseSpeed = 0;
boolean mouseReleased = true;
float[] selectedCorner = null;
String selectedCornerLoc = "";


final int screenPPI = 72; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch. 

//These variables are for my example design. Your input code should modify/replace these!
float screenTransX = 0;
float screenTransY = 0;
float screenRotation = 0;
float screenZ = 50f;

private class Target
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

ArrayList<Target> targets = new ArrayList<Target>();

void setup() {
  size(1000, 800); 

  rectMode(CENTER);
  textFont(createFont("Arial", inchToPix(.3f))); //sets the font to Arial that is 0.3" tall
  textAlign(CENTER);

  //don't change this! 
  border = inchToPix(2f); //padding of 1.0 inches

  for (int i=0; i<trialCount; i++) //don't change this! 
  {
    Target t = new Target();
    t.x = random(-width/2+border, width/2-border); //set a random x with some padding
    t.y = random(-height/2+border, height/2-border); //set a random y with some padding
    t.rotation = random(0, 360); //random rotation between 0 and 360
    int j = (int)random(20);
    t.z = ((j%12)+1)*inchToPix(.25f); //increasing size from .25 up to 3.0" 
    targets.add(t);
    println("created target with " + t.x + "," + t.y + "," + t.rotation + "," + t.z);
  }

  Collections.shuffle(targets); // randomize the order of the button; don't change this.
}



void draw() {

  background(40); //background is dark grey
  fill(200);
  noStroke();

  //shouldn't really modify this printout code unless there is a really good reason to
  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, inchToPix(.4f));
    text("User had " + errorCount + " error(s)", width/2, inchToPix(.4f)*2);
    text("User took " + (finishTime-startTime)/1000f/trialCount + " sec per target", width/2, inchToPix(.4f)*3);
    text("User took " + ((finishTime-startTime)/1000f/trialCount+(errorCount*errorPenalty)) + " sec per target inc. penalty", width/2, inchToPix(.4f)*4);
    return;
  }

  //===========DRAW DESTINATION SQUARES=================
  for (int i=0; i<trialCount; i++)
  {
    pushMatrix();
    translate(width/2, height/2); //center the drawing coordinates to the center of the screen
    Target t = targets.get(i);
    translate(t.x, t.y); //center the drawing coordinates to the center of the screen
    rotate(radians(t.rotation));
    if (trialIndex==i)
      fill(255, 0, 0, 192); //set color to semi translucent
    else
      fill(128, 60, 60, 128); //set color to semi translucent
    rect(0, 0, t.z, t.z);
    popMatrix();
  }

  //===========DRAW CURSOR SQUARE=================
  pushMatrix();
  translate(width/2, height/2); //center the drawing coordinates to the center of the screen
  translate(screenTransX, screenTransY);
  rotate(radians(screenRotation));
  noFill();
  strokeWeight(3f);
  if (checkForSuccess()) 
    stroke(0, 255, 0);
  else
    stroke(160);
  rect(0, 0, screenZ, screenZ);
  popMatrix();

  //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  scaffoldControlLogic(); //you are going to want to replace this!
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchToPix(.8f));
}




// function to find out corner coordinates, given coordinates relative to center
float[] findCornerXY(float relX, float relY) {
   float theta = radians(screenRotation);
   float[] cornerXY = new float[2];
   float cornerX = (screenTransX + (relX) * cos(-theta) + (relY) * sin(-theta)) + width/2;
   float cornerY = (screenTransY - (relX) * sin(-theta) + (relY) * cos(-theta)) + height/2;
   cornerXY[0] = cornerX;
   cornerXY[1] = cornerY;
   return cornerXY;
}

boolean insideScreen(float screenTransX, float screenTransY, float screenZ) {
  pushMatrix();
  
  rotate(radians(screenRotation));
  
  boolean inside = (mouseX - width/2 <= screenTransX + screenZ/2 &&
      mouseX - width/2 >= screenTransX - screenZ/2 &&
      mouseX - height/2 >= screenTransY - screenZ/2 &&
      mouseY - height/2 <= screenTransY + screenZ/2);
      
  popMatrix();
  
  return inside;
  
  
}

    

//my example design for control, which is terrible
void scaffoldControlLogic()
{
    //upper left corner, rotate counterclockwise
    //text("CCW", inchToPix(.4f), inchToPix(.4f));
    //if (mousePressed && dist(0, 0, mouseX, mouseY)<inchToPix(.8f))
    //  screenRotation--;
    
    float[] botRCorner = findCornerXY(screenZ/2, screenZ/2);
    float[] botLCorner = findCornerXY(-screenZ/2, screenZ/2);
    float[] topRCorner = findCornerXY(screenZ/2, -screenZ/2);
    float[] topLCorner = findCornerXY(-screenZ/2, -screenZ/2);
    
    mouseSpeed = dist(mouseX, mouseY, pmouseX, pmouseY);
    
    float cornerRadius = constrain(screenZ*0.4, 10, 30); //leave min and max alone!

    //println(selectedCornerLoc);
    
    if (selectedCorner == null) {
    
      // find if mouse near corner 
      if (dist(mouseX, mouseY, topRCorner[0], topRCorner[1]) <= cornerRadius) {
        selectedCorner = topRCorner;
        selectedCornerLoc = "TR";
      }
      else if (dist(mouseX, mouseY, topLCorner[0], topLCorner[1]) <= cornerRadius) {
        selectedCorner = topLCorner;
        selectedCornerLoc = "TL";
      }
      else if (dist(mouseX, mouseY, botLCorner[0], botLCorner[1]) <= cornerRadius) {
        selectedCorner = botLCorner;
        selectedCornerLoc = "BL";
      }
      else if (dist(mouseX, mouseY, botRCorner[0], botRCorner[1]) <= cornerRadius) {
        selectedCorner = botRCorner;
        selectedCornerLoc = "BR";
      }
      else {
        selectedCorner = null;
        selectedCornerLoc = "";
      }
    
    } 

    //if mouse near corner, draw circle
    if (selectedCorner != null) {
      ellipse(selectedCorner[0], selectedCorner[1], cornerRadius, cornerRadius);
    }
    
    if (mousePressed && mouseDragged && selectedCorner != null) {
    
      if (selectedCornerLoc == "TR")
        selectedCorner = findCornerXY(screenZ/2, -screenZ/2);
      else if (selectedCornerLoc == "TL")
        selectedCorner = findCornerXY(-screenZ/2, -screenZ/2);
      else if (selectedCornerLoc == "BL")
        selectedCorner = findCornerXY(-screenZ/2, screenZ/2);
      else if (selectedCornerLoc == "BR")
        selectedCorner = findCornerXY(screenZ/2, screenZ/2);
       
       
      ellipse(selectedCorner[0], selectedCorner[1], cornerRadius, cornerRadius);
      
      
      
      float mouseAngle = degrees(atan2( ((mouseY-height/2) - screenTransY), ((mouseX - width/2) - screenTransX) ));
      
     
      float cornerAngle = degrees(atan2( ((selectedCorner[1]-height/2) - screenTransY), ((selectedCorner[0] - width/2) - screenTransX) ));
      
      float degreesDifference = mouseAngle - cornerAngle;
      
      screenRotation += degreesDifference; 
     

    }
    else {
      selectedCorner = null;
      selectedCornerLoc = "";
    }
    
    if (mousePressed && mouseDragged) {

      // distance between mouse and center of screen is getting smaller, make size smaller
      if (dist(mouseX - width/2, mouseY - height/2, screenTransX, screenTransY) < dist(pmouseX - width/2, pmouseY - height/2, screenTransX, screenTransY)) {
        screenZ = constrain(screenZ-mouseSpeed*1.5, .01, inchToPix(4f)); //leave min and max alone!
      }
      else {
        screenZ = constrain(screenZ+mouseSpeed*1.5, .01, inchToPix(4f)); //leave min and max alone!
      }
    }
    
    


  //upper right corner, rotate clockwise
  //text("CW", width-inchToPix(.4f), inchToPix(.4f));
  //if (mousePressed && dist(width, 0, mouseX, mouseY)<inchToPix(.8f))
  //  screenRotation++;

  ////lower left corner, decrease Z
  //text("-", inchToPix(.4f), height-inchToPix(.4f));
  //if (mousePressed && dist(0, height, mouseX, mouseY)<inchToPix(.8f))
  //  screenZ = constrain(screenZ-inchToPix(.02f), .01, inchToPix(4f)); //leave min and max alone!

  ////lower right corner, increase Z
  //text("+", width-inchToPix(.4f), height-inchToPix(.4f));
  //if (mousePressed && dist(width, height, mouseX, mouseY)<inchToPix(.8f))
  //  screenZ = constrain(screenZ+inchToPix(.02f), .01, inchToPix(4f)); //leave min and max alone! 
  

  //if (insideScreen(screenTransX, screenTransY, screenZ)) 
  //{
  //  cursor(HAND);
  //  if (mousePressed && mouseDragged) {
  //    screenTransX += mouseX - pmouseX;
  //    screenTransY += mouseY - pmouseY;
  //  }
    
  //}
  //else 
  //  cursor(ARROW);

  
  
 
  
  //left middle, move left
  text("left", inchToPix(.4f), height/2);
  if (mousePressed && dist(0, height/2, mouseX, mouseY)<inchToPix(.8f))
    screenTransX-=inchToPix(.02f);

  text("right", width-inchToPix(.4f), height/2);
  if (mousePressed && dist(width, height/2, mouseX, mouseY)<inchToPix(.8f))
    screenTransX+=inchToPix(.02f);

  text("up", width/2, inchToPix(.4f));
  if (mousePressed && dist(width/2, 0, mouseX, mouseY)<inchToPix(.8f))
    screenTransY-=inchToPix(.02f);

  text("down", width/2, height-inchToPix(.4f));
  if (mousePressed && dist(width/2, height, mouseX, mouseY)<inchToPix(.8f))
    screenTransY+=inchToPix(.02f);
}


void mousePressed()
{
  if (startTime == 0) //start time on the instant of the first user click
  {
    startTime = millis();
    println("time started!");
  }
}


void mouseReleased()
{
  mouseReleased = true;
  //check to see if user clicked middle of screen within 3 inches
  //if (dist(width/2, height/2, mouseX, mouseY)<inchToPix(3f))
  //{
  //  if (userDone==false && !checkForSuccess())
  //    errorCount++;

  //  trialIndex++; //and move on to next trial

  //  if (trialIndex==trialCount && userDone==false)
  //  {
  //    userDone = true;
  //    finishTime = millis();
  //  }
  //}
}

void mouseDragged() {
  mouseDragged = true;
}

void keyPressed()
{
  if (userDone==false && !checkForSuccess())
      errorCount++;

    trialIndex++; //and move on to next trial

    if (trialIndex==trialCount && userDone==false)
    {
      userDone = true;
      finishTime = millis();
    }
}

//probably shouldn't modify this, but email me if you want to for some good reason.
public boolean checkForSuccess()
{
  Target t = targets.get(trialIndex);  
  boolean closeDist = dist(t.x, t.y, screenTransX, screenTransY)<inchToPix(.05f); //has to be within +-0.05"
  boolean closeRotation = calculateDifferenceBetweenAngles(t.rotation, screenRotation)<=5;
  boolean closeZ = abs(t.z - screenZ)<inchToPix(.05f); //has to be within +-0.05"  

  println("Close Enough Distance: " + closeDist + " (cursor X/Y = " + t.x + "/" + t.y + ", target X/Y = " + screenTransX + "/" + screenTransY +")");
  println("Close Enough Rotation: " + closeRotation + " (rot dist="+calculateDifferenceBetweenAngles(t.rotation, screenRotation)+")");
  println("Close Enough Z: " +  closeZ + " (cursor Z = " + t.z + ", target Z = " + screenZ +")");
  println("Close enough all: " + (closeDist && closeRotation && closeZ));

  return closeDist && closeRotation && closeZ;
}

//utility function I include to calc diference between two angles
double calculateDifferenceBetweenAngles(float a1, float a2)
{
  double diff=abs(a1-a2);
  diff%=90;
  if (diff>45)
    return 90-diff;
  else
    return diff;
}

//utility function to convert inches into pixels based on screen PPI
float inchToPix(float inch)
{
  return inch*screenPPI;
}
