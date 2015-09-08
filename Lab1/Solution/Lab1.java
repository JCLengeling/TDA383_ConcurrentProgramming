import TSim.*;
import java.util.*;

public class Lab1 {
	
	Thread first,second;
	HashMap<Integer, Touple> sensorLocation = new HashMap<Integer, Touple>();
	
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		 new Lab1(args);
	}
	
  public Lab1(String[] args) {
    TSimInterface tsi = TSimInterface.getInstance();
    
   
    sensorLocation.add(1, new Touple(7,8));
    sensorLocation.add(2, new Touple(8,6));
    sensorLocation.add(3, new Touple(16,7));
    sensorLocation.add(4, new Touple(16,8));
    sensorLocation.add(5, new Touple(15,10));
    sensorLocation.add(6, new Touple(14,9));
    sensorLocation.add(7, new Touple(4,10));
    sensorLocation.add(8, new Touple(5,9));
    sensorLocation.add(9, new Touple(3,12));
    sensorLocation.add(10, new Touple(4,11));    
    
    try {
       first = new Thread(new Train(tsi,1 ,Integer.valueOf(args[0]).intValue()));
       second = new Thread(new Train(tsi,2,Integer.valueOf(args[1]).intValue()));
      
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
	private boolean inStation = true;
	public Train(TSimInterface tsi,int id, int speed)throws CommandException {
		this.tsi = tsi;		
		this.speed = speed;
		this.id = id;
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
			 if(tmpX == 16 ){
				 if (tmpY == 3 || tmpY ==  5 || tmpY == 11 || tmpY==13 ){
					 if (status == 2)
						 inStation = false;
					 else
						 inStation = true;
				 }
				 
				 if (tmpY == 7) {
					 if(status == 2) {Thread.sleep(1000);this.tsi.setSwitch(17,7,1);}
					 else {
						 
						 this.tsi.setSwitch(17,7,2);
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
