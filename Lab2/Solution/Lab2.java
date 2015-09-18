import TSim.*;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.locks.*;


public class Lab2 {

    Thread firstTrain, secondTrain;
    public HashMap<Integer, Touple> sensorLocation = new HashMap<Integer, Touple>();
    public Monitor[] monitors = new Monitor[9];

    public static void main(String[] args) {
        // TODO Auto-generated method stub
        new Lab2(args);
    }

    public Lab2(String[] args) {
        TSimInterface tsi = TSimInterface.getInstance();

        //For easy lookup store sensor locations in the sensorLocation HashMap
        //The SensorID (see lab handin) is used as key and we created a Tuple class to store the X and Y coordinates

        sensorLocation.put(1, new Touple(9, 5));
        sensorLocation.put(2, new Touple(6, 6));
        sensorLocation.put(3, new Touple(11, 7));
        sensorLocation.put(4, new Touple(10, 8));
        sensorLocation.put(5, new Touple(14, 7));
        sensorLocation.put(6, new Touple(15, 8));
        sensorLocation.put(7, new Touple(19, 8));
        sensorLocation.put(8, new Touple(18, 9));
        sensorLocation.put(9, new Touple(12, 9));
        sensorLocation.put(10, new Touple(13, 10));
        sensorLocation.put(11, new Touple(7, 9));
        sensorLocation.put(12, new Touple(6, 10));
        sensorLocation.put(13, new Touple(1, 9));
        sensorLocation.put(14, new Touple(1, 10));
        sensorLocation.put(15, new Touple(6, 11));
        sensorLocation.put(16, new Touple(4, 13));

        //Create monitors and store them in the monitors array
        //See also picture in lab handin; A is stored at index 0, B at index 1 and so on
        //There are two special cases though since at the beginning two trains start already on reserved tracks.

        for (int i = 0; i < 9; i++) {
            if (i == 0 || i == 7) monitors[i] = new Monitor(true);
            else monitors[i] = new Monitor(false);
        }

        try {
            firstTrain = new Thread(new Train(tsi, 1, Integer.valueOf(args[0]).intValue(), true, 0, this));
            secondTrain = new Thread(new Train(tsi, 2, Integer.valueOf(args[1]).intValue(), false, 7, this));
        } catch (CommandException e) {
            e.printStackTrace();    // or only e.getMessage() for the error
            System.exit(1);
        }
        secondTrain.start();
        firstTrain.start();
    }
}

class Touple {
    private int x, y;

    public Touple(int x, int y) {
        this.x = x;
        this.y = y;
    }

    public int getX() {
        return this.x;
    }

    public int getY() {
        return this.y;
    }
}



class Monitor {
	
	private final Lock lock;
	private final Lock tryLock;
	private final Condition condition;
	private boolean isTaken;
	public Monitor(boolean isTaken){
		lock = new ReentrantLock();
		tryLock = new ReentrantLock();
		condition = lock.newCondition();
		this.isTaken = isTaken;
	}
	public void leave() throws InterruptedException{
		lock.lock();
		isTaken = false;
		condition.signal();
		lock.unlock();
	}
	
	public void enter() throws InterruptedException {
		lock.lock();
		if (isTaken) condition.await();
		isTaken = true;
		lock.unlock();
	}
	
	public boolean tryEnter() throws InterruptedException{
		tryLock.lock();
		if(!isTaken){
			this.enter();
			tryLock.unlock();
			return true;
		}
		else{			
			tryLock.unlock();
			return false;
		}
	}
	
	
}

class Train implements Runnable {
    private TSimInterface tsi;
    private boolean goesDown;
    private int currentSection,id, speed;
    private Lab2 main;

    public Train(TSimInterface tsi, int id, int speed, boolean goesDown, int currentSection, Lab2 main) throws CommandException {
        this.tsi = tsi;
        this.speed = speed;
        this.id = id;
        this.main = main;
        this.goesDown = goesDown;
        this.currentSection = currentSection;
        try {
            this.tsi.setSpeed(id, speed);
        } catch (CommandException e) {
            throw e;
        }
    }

    public void run() {
        while (true) {
            try {
                int tmpY = 0, tmpX = 0, status = -1, currentSensor = -1;
                SensorEvent event = tsi.getSensor(this.id);
                tmpY = event.getYpos();
                tmpX = event.getXpos();
                status = event.getStatus();

                //retrieve which sensor we just hit
                for (Map.Entry<Integer, Touple> entry : main.sensorLocation.entrySet()) {
                    Touple value = entry.getValue();
                    if (value.getX() == tmpX && value.getY() == tmpY) {
                        currentSensor = entry.getKey();
                    }

                }

                //Do stuff, when  a sensor becomes active (status ==1)  and according to sensorID/direction we are heading
                if (this.goesDown && status == 1) {
                    switch (currentSensor) {
                        case 1:
                        case 2:
                            //Special Case enter C
                            tsi.setSpeed(this.id, 0);
                            main.monitors[2].enter();
                            tsi.setSpeed(this.id, this.speed);
                            break;
                        case 3:
                        case 4:
                            //Special Case leave C;
                            main.monitors[2].leave();
                            break;
                        case 5:
                            //enter D and if free set Switch
                            tsi.setSpeed(this.id, 0);
                            main.monitors[3].enter();
                            tsi.setSpeed(this.id, this.speed);
                            tsi.setSwitch(17, 7, 2);
                            break;
                        case 6:
                            //enter D and if free set Switch
                            tsi.setSpeed(this.id, 0);
                            main.monitors[3].enter();
                            tsi.setSpeed(this.id, this.speed);
                            tsi.setSwitch(17, 7, 1);
                            break;
                        case 7:
                            //leave currentSection, name currentSection and leave
                            main.monitors[currentSection].leave();
                            currentSection = 3;
                            break;
                        case 8:
                            //enter E, if fails enter F and set switch accordingly;

                            if (main.monitors[4].tryEnter()) {
                                tsi.setSwitch(15, 9, 2);
                            } else {
                                main.monitors[5].enter();
                                tsi.setSwitch(15, 9, 1);
                            }
                            break;
                        case 9:
                            //leave currentSection, name currentSection and leave
                            main.monitors[currentSection].leave();
                            currentSection = 4;
                            break;
                        case 10:
                            //leave currentSection, name currentSection and leave
                            main.monitors[currentSection].leave();
                            currentSection = 5;
                            break;
                        case 11:
                            //enter G and if free set Switch
                            tsi.setSpeed(this.id, 0);
                            main.monitors[6].enter();
                            tsi.setSpeed(this.id, this.speed);
                            tsi.setSwitch(4, 9, 1);
                            break;
                        case 12:
                            //enter G and if free set Switch
                            tsi.setSpeed(this.id, 0);
                            main.monitors[6].enter();
                            tsi.setSpeed(this.id, this.speed);
                            tsi.setSwitch(4, 9, 2);
                            break;
                        case 13:
                            //leave currentSection, name currentSection and leave
                            main.monitors[currentSection].leave();
                            currentSection = 6;
                            break;
                        case 14:
                            //enter H, if fails enter I and set switch accordingly;
                            if (main.monitors[7].tryEnter()) {// might be problem with switches
                                tsi.setSwitch(3, 11, 1);
                            } else {
                                main.monitors[8].enter();
                                tsi.setSwitch(3, 11, 2);
                            }
                            break;
                        case 15:
                            //leave currentSection, name currentSection and leave
                            main.monitors[currentSection].leave();
                            currentSection = 7;
                            break;
                        case 16:
                            //leave currentSection, name currentSection and leave
                            main.monitors[currentSection].leave();
                            currentSection = 8;
                            break;
                        default:
                            //change direction in station
                            this.goesDown = !this.goesDown;
                            this.tsi.setSpeed(this.id, 0);
                            Thread.sleep(2 * 20 * Math.abs(this.speed) + 1500);
                            this.speed = this.speed * -1;
                            this.tsi.setSpeed(this.id, this.speed);
                            break;
                    }
                } else if (!this.goesDown && status == 1) {
                    switch (currentSensor) {
                        case 1:
                        case 2:
                            //leave crossing;
                            main.monitors[2].leave();
                            break;
                        case 3:
                        case 4:
                            // stop, enter crossing C, cross it
                            tsi.setSpeed(this.id, 0);
                            main.monitors[2].enter();
                            tsi.setSpeed(this.id, this.speed);
                            break;
                        case 5:
                            //leave current section and set new current section A
                            main.monitors[currentSection].leave();
                            currentSection = 0;
                            break;
                        case 6:
                            //leave current section and set new current section B
                            main.monitors[currentSection].leave();
                            currentSection = 1;
                            break;
                        case 7:
                            //try enter A if fails, enter B, set switch
                            if (main.monitors[0].tryEnter()) {
                                tsi.setSwitch(17, 7, 2);
                            } else {
                                main.monitors[1].enter();
                                tsi.setSwitch(17, 7, 1);
                            }
                            break;
                        case 8:
                            //leave current section and set new current section D
                            main.monitors[currentSection].leave();
                            currentSection = 3;
                            break;
                        case 9:
                            //enter D and set switch accordingly
                            tsi.setSpeed(this.id, 0);
                            main.monitors[3].enter();
                            tsi.setSpeed(this.id, this.speed);
                            tsi.setSwitch(15, 9, 2);
                            break;
                        case 10:
                            //enter D and set switch accordingly
                            tsi.setSpeed(this.id, 0);
                            main.monitors[3].enter();
                            tsi.setSpeed(this.id, this.speed);
                            tsi.setSwitch(15, 9, 1);
                            break;
                        case 11:
                            //leave G and set new currentSection to E
                            main.monitors[currentSection].leave();
                            currentSection = 4;
                            break;
                        case 12:
                            //leave G and set new currentSection to F
                            main.monitors[currentSection].leave();
                            currentSection = 5;
                            break;
                        case 13:
                            // try to enter E, if it fails, enter F and set switch accordingly
                            if (main.monitors[4].tryEnter()) {
                                tsi.setSwitch(4, 9, 1);
                            } else {
                                main.monitors[5].enter();
                                tsi.setSwitch(4, 9, 2);
                            }
                            break;
                        case 14:
                            // leave current section, set a new one to G
                            main.monitors[currentSection].leave();
                            currentSection = 6;
                            break;
                        case 15:
                            //enter G set switch up
                            tsi.setSpeed(this.id, 0);
                            main.monitors[6].enter();
                            tsi.setSpeed(this.id, this.speed);
                            tsi.setSwitch(3, 11, 1);
                            break;
                        case 16:
                            //enter G set switch down
                            tsi.setSpeed(this.id, 0);
                            main.monitors[6].enter();
                            tsi.setSpeed(this.id, this.speed);
                            tsi.setSwitch(3, 11, 2);
                            break;
                        default:
                            //change direction in station
                            this.goesDown = !this.goesDown;
                            this.tsi.setSpeed(this.id, 0);
                            Thread.sleep(2 * 20 * Math.abs(this.speed) + 1500);
                            this.speed = this.speed * -1;
                            this.tsi.setSpeed(this.id, this.speed);
                            break;
                    }
                }
            } catch (Exception e) {
                System.err.println(e);
            }
        }

    }
}
