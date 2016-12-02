import controlP5.ControlP5;
import processing.core.PGraphics;
import processing.opengl.PShader;
  
/**
 * Ported from the THREE.js SSAO implementation: https://threejs.org/examples/webgl_postprocessing_ssao.html
 * With help from the Processing Forum: https://forum.processing.org/two/discussion/2153/how-to-render-z-buffer-depth-pass-image-of-a-3d-scene
 */
  
PGraphics canvas;
PGraphics depth;
PShader depthShader;
PShader ssaoShader;
float loopFrames = 500.0;
float percentComplete;
float progressRads;
boolean debug = true;

ControlP5 cp5;
boolean onlyAO, onlyAODefault = false;
float aoClamp, aoClampDefault = 1.9;
float lumInfluence, lumInfluenceDefault = -3.7;
float cameraNear, cameraNearDefault = 160.0;
float cameraFar, cameraFarDefault = 660.0;
int samples, samplesDefault = 75;
float radius, radiusDefault = 34.0;
float diffArea, diffAreaDefault = 0.65;
float gDisplace, gDisplaceDefault = 2.3;
float diffMult, diffMultDefault = 100;
float gaussMult, gaussMultDefault = -2.0;
boolean useNoise, useNoiseDefault = false;
float noiseAmount, noiseAmountDefault = 0;


public void settings() {
  size(800, 600, P3D);
}

public void setup() {    
  // controls
  cp5 = new ControlP5(this);
  int spacing = 20;
  int cntrlY = 0;
  int cntrlW = 100;
  
  cp5.addToggle("onlyAO").setPosition(20,cntrlY+=spacing).setWidth(cntrlW).setHeight(10).setValue(onlyAODefault);
  cp5.addSlider("aoClamp").setPosition(20,cntrlY+=spacing+10).setWidth(cntrlW).setRange(-5.0,5.0).setValue(aoClampDefault);
  cp5.addSlider("lumInfluence").setPosition(20,cntrlY+=spacing).setWidth(cntrlW).setRange(-5.0,5.0).setValue(lumInfluenceDefault);
  cp5.addSlider("cameraNear").setPosition(20,cntrlY+=spacing).setWidth(cntrlW).setRange(1.0,2000.0).setValue(cameraNearDefault);
  cp5.addSlider("cameraFar").setPosition(20,cntrlY+=spacing).setWidth(cntrlW).setRange(1.0,2000.0).setValue(cameraFarDefault);
  cp5.addSlider("samples").setPosition(20,cntrlY+=spacing).setWidth(cntrlW).setRange(2,128).setValue(samplesDefault);
  cp5.addSlider("radius").setPosition(20,cntrlY+=spacing).setWidth(cntrlW).setRange(1.0,50.0).setValue(radiusDefault);
  cp5.addSlider("diffArea").setPosition(20,cntrlY+=spacing).setWidth(cntrlW).setRange(0,5.0).setValue(diffAreaDefault);
  cp5.addSlider("gDisplace").setPosition(20,cntrlY+=spacing).setWidth(cntrlW).setRange(0,5.0).setValue(gDisplaceDefault);
  cp5.addSlider("diffMult").setPosition(20,cntrlY+=spacing).setWidth(cntrlW).setRange(1.0,1000.0).setValue(diffMultDefault);
  cp5.addSlider("gaussMult").setPosition(20,cntrlY+=spacing).setWidth(cntrlW).setRange(-4.0,2.0).setValue(gaussMultDefault);
  cp5.addToggle("useNoise").setPosition(20,cntrlY+=spacing).setWidth(cntrlW).setHeight(10).setValue(useNoiseDefault);
  cp5.addSlider("noiseAmount").setPosition(20,cntrlY+=spacing+10).setWidth(cntrlW).setRange(0, 0.003).setValue(noiseAmountDefault);

  // create depth & draw buffers
  canvas = createGraphics(width, height, P3D);
  canvas.smooth(8);
  
  depth = createGraphics(width, height, P3D);
  depth.smooth(8);
  
  // load shaders
  depthShader = loadShader("depth-frag.glsl", "depth-vert.glsl");

  ssaoShader = loadShader("ssao-frag.glsl", "ssao-vert.glsl");
  ssaoShader.set("size", (float) width, (float) height );
  ssaoShader.set("tDiffuse", canvas );
  ssaoShader.set("tDepth", depth );
}

public void draw() {
    background(0);
    
    // update shader uniforms from ControlP5 sliders
    depthShader.set("near", cameraNear );
    depthShader.set("far", cameraFar );

    ssaoShader.set("onlyAO", onlyAO );
    ssaoShader.set("aoClamp", aoClamp );
    ssaoShader.set("lumInfluence", lumInfluence );
    ssaoShader.set("cameraNear", cameraNear );
    ssaoShader.set("cameraFar", cameraFar );
    ssaoShader.set("samples", samples);
    ssaoShader.set("radius", radius);
    ssaoShader.set("diffArea", diffArea);
    ssaoShader.set("gDisplace", gDisplace);
    ssaoShader.set("diffMult", diffMult);
    ssaoShader.set("gaussMult", gaussMult);    
    ssaoShader.set("useNoise", useNoise);
    ssaoShader.set("noiseAmount", noiseAmount);

    // rendering progress
    percentComplete = ((float)(frameCount%loopFrames)/loopFrames);
    progressRads = percentComplete * TWO_PI;

    // draw depth map buffer
    depth.shader(depthShader);
    drawShapes(depth, false);
    
    // draw shapes to draw target buffer
    drawShapes(canvas, true);
    
    // combine 2 buffers and draw to screen via SSAO
    ssaoShader.set("tDiffuse", canvas );
    ssaoShader.set("tDepth", depth );
    filter(ssaoShader);
    
    // debug display
    if(debug == true) {
      // show offscreen buffers
      image(canvas, 0, height - 100, 100, 100);
      image(depth, 100, height - 100, 100, 100);
    } else {
      // hide Controls
      translate(width * 5, 0);
    }
}

public void drawShapes(PGraphics pg, boolean addLights) {
  // draw setup
  pg.beginDraw();
  pg.clear();
  pg.imageMode( PConstants.CENTER );
  pg.rectMode( PConstants.CENTER );
  pg.ellipseMode( PConstants.CENTER );
  pg.shapeMode( PConstants.CENTER );
  pg.sphereDetail(7);
  pg.noStroke();
      
  // move to canvas center
  pg.translate(pg.width/2, pg.height/2, 0);
  
  // lighting
  if(addLights == true) pg.lights();
  
  // draw some shapes
  drawShapes(pg);
  pg.endDraw();
}

public void drawShapes(PGraphics pg) {
  // spin scene
  pg.rotateY(sin(progressRads) * 0.3);
  
  // draw plane
  pg.fill(127);
  pg.rect(0, 0, width * 3, height * 3);

  // draw boxen
  for (float i = 0; i < 10; i++) {
    pg.fill(60.0 + 55.0 * sin(i), 170.0 + 35.0 * cos(i * 2.0), 150.0 + 75.0 * sin(i));
    pg.pushMatrix();
    pg.rotateX(i + 2.0 * TWO_PI * noise(i + 0.03 * cos(i + progressRads)));
    pg.rotateY(i + -1 + 2 * noise(i + 0.03 * sin(i + progressRads)));
    pg.rotateZ(i + -1 + 2 * noise(i + 0.03 * sin(i + progressRads)));
    pg.box(
        pg.height * 0.7 + 0.2 * sin(i + progressRads),
        pg.height * 0.1 + 0.05 * sin(i + progressRads),
        pg.height * 0.1 + 0.05 * sin(i + progressRads)
        );
    pg.popMatrix();
  }
}

public void keyPressed() {
  if(key == ' ') {
    debug = !debug;
  }
}