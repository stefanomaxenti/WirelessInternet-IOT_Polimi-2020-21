/*
 *  @author Luca Pietro Borsani
 */

generic configuration RandomGeneratorC() {

	provides interface Read<uint16_t>;

} implementation {

	components MainC, RandomC;
	components new RandomGeneratorP();

	//Connects the provided interface
	Read = RandomGeneratorP;

	//Random interface and its initialization
	RandomGeneratorP.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;

}
