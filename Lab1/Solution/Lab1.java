import TSim.*;
import java.util.HashMap; 
import java.util.Map; 

public class Lab1 {
	
	Thread first,second;
	HashMap<Integer, Touple> sensorLocation = new HashMap<Integer, Touple>();
	
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		 new Lab1(args);
	}
	
  public Lab1(String[] args) {
    TSimInterface tsi = TSimInterface.getInstance();
    
    sensorLocation.put(1, new Touple(7,8));
    sensorLocation.put(2, new Touple(8,6));
    sensorLocation.put(3, new Touple(16,7));
    sensorLocation.put(4, new Touple(16,8));
    sensorLocation.put(5, new Touple(15,10));
    sensorLocation.put(6, new Touple(14,9));
    sensorLocation.put(7, new Touple(4,10));
    sensorLocation.put(8, new Touple(5,9));
    sensorLocation.put(9, new Touple(3,12));
    sensorLocation.put(10, new Touple(4,11));    
    
    try {
       first = new Thread(new Train(tsi,1 ,Integer.valueOf(args[0]).intValue(), sensorLocation));
       second = new Thread(new Train(tsi,2,Integer.valueOf(args[1]).intValue(), sensorLocation));
      
    }
    catch (CommandException e) {
      e.printStackTrace();    // or only e.getMessage() for the error
      System.exit(1);
    }
    second.start();
    first.start();
  }
}

class Touple {
	private int x, y;
	public Touple(int x, int y){
		this.x = x; 
		this.y = y;
	}
	public int getX(){return this.x;}
	public int getY(){return this.y;}	 
}

class Train implements Runnable {
	private TSimInterface tsi;
	private int id, speed;
	HashMap<Integer, Touple> sensorLocation;
	private boolean inStation = true;
	public Train(TSimInterface tsi,int id, int speed, HashMap<Integer, Touple> sensorLocation)throws CommandException {
		this.tsi = tsi;		
		this.speed = speed;
		this.id = id;
		this.sensorLocation = sensorLocation;
		 try {
			 this.tsi.setSpeed(id,speed);
			 }
		 catch (CommandException e) {
		     throw e;
		    }
		 }
	
	public void run() {
		while(true) {
		 try {
			 SensorEvent event = tsi.getSensor(this.id);
			 if(this.id == 1) System.err.println(event.toString()); 
			 
			 int tmpY = 0, tmpX= 0, status = -1 ;
			 tmpY = event.getYpos();
			 tmpX = event.getXpos();
			 status = event.getStatus();
			 
			 int currentSensor = -1;
			 
			 for(Map.Entry<Integer, Touple> entry : sensorLocation.entrySet()) {
				    
				    Touple value = entry.getValue();
				    
				    if (value.getX() == tmpX && value.getY() == tmpY){
				    	currentSensor = entry.getKey();
				    }

				}
			
			 
			if(currentSensor == -1){
				if(tmpX == 16 ){
				 if (tmpY == 3 || tmpY ==  5 || tmpY == 11 || tmpY==13 ){
					 if (status == 2)
						 inStation = false;
					 else
						 inStation = true;
				 	}
				}
			}		 
			 
			 if (inStation ){
				 this.tsi.setSpeed(this.id, 0);
				 Thread.sleep(2*20*Math.abs(this.speed) +1500);
				 this.speed = this.speed *-1;
				 this.tsi.setSpeed(this.id,this.speed);
			 }
			 
			 }
		 catch (Exception e) {
			 	System.err.println(e);
		    }
		}
					
	}
}
