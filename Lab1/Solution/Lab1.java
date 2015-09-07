import TSim.*;


public class Lab1 {
	
	Thread first,second;
	
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		 new Lab1(args);
	}
	
  public Lab1(String[] args) {
    TSimInterface tsi = TSimInterface.getInstance();
    
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

class Train implements Runnable {
	private TSimInterface tsi;
	private int id, speed;
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
			 System.err.println(tsi.getSensor(this.id).toString()); 
			 }
		 catch (Exception e) {
			 	System.err.println(e);
		    }
		}
					
	}
}
