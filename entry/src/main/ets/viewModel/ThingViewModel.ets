import ThingModel from '../model/ThingModel';

@Observed
export default class ThingViewModel {
  @Track thingName: string = 'Todo';
  @Track isFinish: boolean = false;

  updateTask(thing: ThingModel) {
    this.thingName = thing.thingName;
    this.isFinish = thing.isFinish;
  }
  updateIsFinish(): void {
    this.isFinish = !this.isFinish;
  }
  addSuffixes(): void {
    this.thingName += '完成啦';
  }
}